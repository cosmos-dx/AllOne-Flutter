import 'dart:convert';
import 'dart:ffi';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/pages/HomePage.dart';
import 'package:planner_app/pages/NoteViewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AllOneNotes(),
      debugShowCheckedModeBanner: false,
    );
  }
}

const backgroundColor = Color.fromARGB(255, 0, 0, 0);
const botBackgroundColor = Color.fromARGB(255, 0, 0, 0);

class AllOneNotes extends StatefulWidget {
  const AllOneNotes({super.key});

  @override
  State<AllOneNotes> createState() => _AllOneNotesState();
}

class _AllOneNotesState extends State<AllOneNotes> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late bool isLoading;
  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> mpdata = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> searchresults = [];
  @override
  void initState() {
    super.initState();

    fetchDataFromFirebase().then((value) => {
          loadAllDataFromSharedPreferences().then((data) {
            setState(() {
              allData.addAll(data);
              copyContentFromAllDataToMpdata();
            });
          })
        });
    setState(() {
      searchresults = mpdata;
    });
  }

  void copyContentFromAllDataToMpdata() {
    if (mpdata.isNotEmpty && allData.isNotEmpty)
      for (var mpdataItem in mpdata) {
        for (var allDataItem in allData) {
          if (json.decode(allDataItem[allDataItem.keys.first])["id"] ==
              mpdataItem[allDataItem.keys.first]?["id"]) {
            if (mpdataItem[allDataItem.keys.first]["content"].length > 0 &&
                json
                        .decode(allDataItem[allDataItem.keys.first])["content"]
                        .length <
                    1) continue;
            mpdataItem[allDataItem.keys.first]["content"] =
                json.decode(allDataItem[allDataItem.keys.first])["content"];
          }
        }
      }
  }

  Future<List<Map<String, dynamic>>> loadAllDataFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();
    List<Map<String, dynamic>> dataList = [];

    for (String key in keys) {
      dynamic value = prefs.get(key);
      Map<String, dynamic> dataEntry = {
        key: value,
      };
      dataList.add(dataEntry);
    }

    return dataList;
  }

  Future<void> fetchDataFromFirebase() async {
    try {
      final user = auth.currentUser;
      final userId = user?.uid;
      DocumentSnapshot userDocument =
          await _firestore.collection('AllOneNotes').doc(userId).get();

      if (userDocument.exists) {
        Map<String, dynamic> data = userDocument.data() as Map<String, dynamic>;

        List<Map<String, dynamic>> notes = [];

        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            notes.add({key: value});
          }
        });

        setState(() {
          mpdata.addAll(notes);
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  List<Map<String, dynamic>> searchInList(
      List<Map<String, dynamic>> list, String searchString) {
    List<Map<String, dynamic>> results = [];

    for (var item in list) {
      item.forEach((key, value) {
        if (key.toLowerCase().startsWith(searchString.toLowerCase())) {
          results.add(item);
        }
      });
    }
    setState(() {
      searchresults = results;
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          toolbarHeight: 50,
          title: Row(
            children: [
              Text(
                "AllOne Notes",
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Image.asset(
                'assets/allOneNotes.png',
                height: 30,
                width: 30,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        body: WillPopScope(
          child: Stack(
            children: [
              Positioned(
                left: -80,
                top: -30,
                width: 350,
                height: 350,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.pink,
                        Colors.blue,
                        Colors.indigo,
                      ],
                      transform: GradientRotation(3.6),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -80,
                bottom: -50,
                width: 350,
                height: 350,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange,
                        Colors.pink,
                        Colors.blue,
                        Colors.indigo,
                      ],
                      transform: GradientRotation(6.5),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                searchInList(mpdata, _searchController.text);
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16.0),
                                hintText: "Search for Notes",
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: ListView(
                        children: [
                          Column(children: buildRowsFromData(searchresults))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          onWillPop: () async {
            return true;
          },
        ),
      ),
    );
  }

  List<Widget> buildRowsFromData(List<Map<String, dynamic>> data) {
    List<Widget> rows = [];

    for (int i = 0; i < data.length; i += 2) {
      List<Widget> rowChildren = [];

      for (int j = i; j < i + 2 && j < data.length; j++) {
        rowChildren.add(NoteCard(passingData: data[j], isAddNote: false));
      }

      if (i + 1 >= data.length) {
        rowChildren.add(NoteCard(passingData: {}, isAddNote: true));
      } else if (i + 2 >= data.length) {
        rowChildren.add(NoteCard(passingData: {}, isAddNote: true));
      }

      rows.add(Row(
        children: rowChildren,
      ));
    }
    return rows;
  }
}

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> passingData;
  final bool isAddNote;
  NoteCard({required this.passingData, required this.isAddNote});
  String passingDataKey = '';
  String passingDataContent = '';
  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Widget build(BuildContext context) {
    if (passingData.isNotEmpty) {
      passingDataKey = passingData.keys.first;
      passingDataContent = passingData[passingDataKey]['content'];
    }
    bool containsSpecialCharacters(String noteName) {
      final pattern = RegExp(r'[!@#$%^&*()_+{}\[\]:;<>,.?~\\|/]');

      return pattern.hasMatch(noteName);
    }

    if (isAddNote && passingData.isEmpty) {
      Map<String, dynamic> addingData = {};
      final uuid = Uuid();
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String noteName = '';
                  String noteContent = '';
                  String title = 'Add Note';
                  return AlertDialog(
                    title: Text(title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextField(
                          onChanged: (value) {
                            noteName = value;
                          },
                          decoration: InputDecoration(labelText: 'Note Name'),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: Text('Add'),
                        onPressed: () async {
                          if (noteName.isNotEmpty) {
                            bool hasSpecialCharacters =
                                containsSpecialCharacters(noteName);
                            if (hasSpecialCharacters) {
                              //Handle here
                            } else {
                              String id = uuid.v4();
                              addingData[noteName] = {
                                'id': id,
                                'content': noteContent,
                              };
                              try {
                                final user = auth.currentUser;
                                if (user != null) {
                                  final uid = user.uid;

                                  final documentReference = _firestore
                                      .collection('AllOneNotes')
                                      .doc(uid);
                                  await documentReference.set(
                                      addingData, SetOptions(merge: true));
                                  Navigator.of(context).pop();
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (builder) => HomePage()),
                                      (route) => false);
                                } else {
                                  showSnackBar(
                                      context, "You are not authorized.");
                                }
                              } catch (e) {
                                print("Error: $e");
                              }
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Center(
              child: Icon(
                Icons.add,
                size: 50, // Adjust the size as needed
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              showDeleteConfirmationDialog(
                  context, {passingDataKey: passingData[passingDataKey]});
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => NoteViewer(
                    title: passingDataKey,
                    content: passingData[passingDataKey],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(11)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  height: 150,
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(179, 78, 78, 78),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passingDataKey,
                        style: TextStyle(
                            color: Color.fromARGB(189, 255, 255, 255),
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Expanded(
                        child: Text(
                          passingDataContent,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Color.fromARGB(167, 255, 255, 255),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  void showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> datatoDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Note'),
          content: Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                deleteNoteFromData(context, datatoDelete);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => HomePage()),
                    (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  void deleteNoteFromData(
      BuildContext context, Map<String, dynamic> datatoDelete) async {
    final user = auth.currentUser;
    final userId = user?.uid;
    final firestoreInstance = FirebaseFirestore.instance;

    if (userId != null) {
      try {
        final CollectionReference notesCollection =
            firestoreInstance.collection('AllOneNotes');
        final DocumentReference docReference = notesCollection.doc(userId);
        DocumentSnapshot docSnapshot = await docReference.get();
        if (docSnapshot.exists) {
          Map<String, dynamic> documentData =
              docSnapshot.data() as Map<String, dynamic>;
          if (documentData.containsKey(datatoDelete.keys.first)) {
            documentData.remove(datatoDelete.keys.first);
            await docReference.set(documentData);

            print('Deleted key: ${datatoDelete.keys.first}');
          } else {
            print('Key not found: ${datatoDelete.keys.first}');
          }
        } else {
          print('Document not found for user: $userId');
        }
      } catch (e) {
        print('Error deleting document: $e');
      }
    } else {
      print('User is not authenticated.');
    }
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
