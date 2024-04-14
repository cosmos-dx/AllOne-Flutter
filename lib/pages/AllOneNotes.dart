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
  List<Map<String, dynamic>> dataList = [];
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
              mergeData();
            });
          })
        });

    setState(() {
      searchresults = mpdata;
    });
  }

  void mergeData() {
    for (Map<String, dynamic> dataEntry in dataList) {
      String key = dataEntry.keys.first;
      if (key == "secretKeyManager") {
        continue;
      }
      bool found = false;
      for (int i = 0; i < mpdata.length; i++) {
        String mpKey = mpdata[i].keys.first;
        if (mpKey == key) {
          mpdata[i] = dataEntry;
          found = true;
          break;
        }
      }
      if (!found) {
        mpdata.add(dataEntry);
      }
    }
    for (var dl in mpdata) {
      dl.forEach((key, value) {
        if (value is String) {
          dl[key] = json.decode(value);
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> loadAllDataFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();

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
        body: Stack(
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
                // (NoteCard(passingData: mpdata[0], isAddNote: false)),
                Expanded(
                  child: Container(
                      child: buildRowsFromData(context, searchresults)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            await deleteNoteLocally(datatoDelete.keys.first);
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

  Future<void> deleteNoteLocally(String datatodelete) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();
    prefs.remove(datatodelete);
  }

  Widget buildRowsFromData(
      BuildContext context, List<Map<String, dynamic>> searchResults) {
    return ListView(
      children: List.generate(searchResults.length + 1, (index) {
        if (index < searchResults.length) {
          Map<String, dynamic> data = searchResults[index];
          String passingDataKey = data.keys.join();
          String passingDataContent = data[passingDataKey]["content"];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                showDeleteConfirmationDialog(
                    context, {passingDataKey: data[passingDataKey]});
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => NoteViewer(
                      title: passingDataKey,
                      content: data[passingDataKey],
                      updateSearchResults: (updatedData) {
                        setState(() {
                          searchResults[index] = updatedData;
                        });
                      },
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
                          passingDataKey ?? '',
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
                            passingDataContent ?? '',
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
          );
        } else {
          Map<String, dynamic> addingData = {};
          final uuid = Uuid();
          return GestureDetector(
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
                              showSnackBar(
                                  context, "No special Characters allowed !");
                              return;
                            } else if (noteName.toLowerCase().trim() ==
                                "secretkeymanager") {
                              showSnackBar(context,
                                  "Note Name should Not be secretKeyManager");
                              return;
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
            child: Container(
              // Adjust height as needed
              height: 150,
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(11)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                      height: 150,
                      width: MediaQuery.of(context).size.width - 20,
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(179, 78, 78, 78),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 60,
                          color: Colors.white,
                        ),
                      )),
                ),
              ),
            ),
          );
        }
      }),
    );
  }

  bool containsSpecialCharacters(String noteName) {
    final pattern = RegExp(r'[!@#$%^&*()_+{}\[\]:;<>,.?~\\|/]');

    return pattern.hasMatch(noteName);
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
