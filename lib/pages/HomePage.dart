import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:planner_app/Customs/TodoCard.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/pages/AddToDo.dart';
import 'package:intl/intl.dart';
import 'package:planner_app/pages/AllOneNotes.dart';
import 'package:planner_app/pages/CustomBottomSheetClipper.dart';
import 'package:planner_app/pages/LandingPage.dart';
import 'package:planner_app/pages/SignUPPage.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isReloading = true;
  TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchDataFromFirestore();
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        isReloading = false;
      });
    });
  }

  Map<String, dynamic> mp = new Map();
  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  List<dynamic> currentState = [];
  String currentStateKey = "";
  List<String> categories = [];
  Map<String, dynamic> searchResults = new Map();
  List<dynamic> results = [];
  void fetchDataFromFirestore() async {
    final user = auth.currentUser;
    if (user != null) {
      final userId = user.uid;
      final firestore = FirebaseFirestore.instance;
      final document = firestore.collection('AllOneData').doc(userId);

      try {
        final documentSnapshot = await document.get();
        if (documentSnapshot.exists) {
          final data = documentSnapshot.data() as Map<String, dynamic>;
          final firstKey = data.keys.isNotEmpty ? data.keys.first : null;
          if (firstKey != null) {
            setState(() {
              mp = data;
              searchResults = mp;
              categories = mp.keys.toList();
              currentState = mp[firstKey];
              currentStateKey = firstKey;
              isReloading = false;
            });
          }
        } else {}
      } catch (e) {}
    } else {}
  }

  void changeState(String val) {
    this.setState(() {
      currentState = mp[val];
      currentStateKey = val;
    });
  }

  Future<void> saveJsonToFile(
      Map<String, dynamic> data, BuildContext context) async {
    final isGranted = await Permission.storage.isGranted;

    if (!isGranted) {
      final status = await Permission.storage.request();

      if (!status.isGranted) {
        // showSnackBar(context, "Permission to access storage denied.");
        return;
      }
    }

    try {
      final externalDirectory = await getExternalStorageDirectory();

      if (externalDirectory != null) {
        final allOneDirectory = Directory('${externalDirectory.path}/AllOne');
        if (!allOneDirectory.existsSync()) {
          allOneDirectory.createSync(recursive: true);
        }

        final file = File('${allOneDirectory.path}/Creds.json');

        final jsonEncoded = json.encode(data);
        await file.writeAsString(jsonEncoded);
        showSnackBar(context, "Passwords Exported");
      } else {
        showSnackBar(context, "External storage not available.");
      }
    } catch (e) {
      showSnackBar(context, "Error: $e");
    }
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.indigo,
                Colors.blue,
                Colors.pink,
                Colors.orange,
              ],
              transform: GradientRotation(5.8),
            ),
          ),
          child: Center(
            child: ClipPath(
              clipper: CustomBottomSheetClipper(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/github.svg',
                    height: 80,
                    width: 80,
                    color: Colors.white,
                  ),
                  _buildText("GitHub", "https://www.github.com/cosmos-dx"),
                  _buildText("www.github.com/cosmos-dx",
                      "https://www.github.com/cosmos-dx"),
                  Text(
                    "Fork and Give a Star !!!",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void searchInList(Map<String, dynamic> mpdata, String searchingText,
      String searchParentKey) {
    List<dynamic> result = [];
    // print(mpdata);
    if (mpdata.containsKey(searchParentKey) &&
        mpdata[searchParentKey] is List) {
      List<dynamic> dataList = mpdata[searchParentKey];

      for (var item in dataList) {
        String name = item['name'];
        print(name.startsWith(searchingText));
        if (name.startsWith(searchingText)) {
          result.add(item);
        }
      }
    }

    setState(() {
      searchResults[searchParentKey] = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: SizedBox(
          child: Text(
            "AllOne",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              authClass.logout(context);
            },
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage("assets/logout.png"),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 25,
          ),
        ],
        bottom: PreferredSize(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            preferredSize: Size.fromHeight(35)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black87,
        items: [
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (builder) => AllOneNotes()));
              },
              child: Icon(
                Icons.notes_outlined,
                color: Colors.white,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    Colors.indigoAccent,
                    Colors.purple,
                  ])),
              child: InkWell(
                onTap: () {
                  print(auth.currentUser);
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (builder) => AddTodoPage(
                              propData: {},
                              parentKey: currentStateKey,
                              categorieslist: categories)),
                      (route) => false);
                },
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              onTap: () {
                _showBottomSheet(context);
              },
              child: Image.asset(
                'assets/export.png',
                width: 25,
                height: 25,
              ),
            ),
            backgroundColor: Colors.white,
            label: '',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 200,
            margin: EdgeInsets.only(top: 15),
            child: Stack(
              children: [
                if (isReloading)
                  Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!isReloading)
                  Positioned(
                    left: -30,
                    top: 0,
                    width: 250,
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.pink, Colors.transparent]),
                          borderRadius: BorderRadius.circular(300)),
                    ),
                  ),
                Positioned(
                  left: -80,
                  top: -10,
                  width: 260,
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.indigo,
                          Colors.blue,
                          Colors.pink,
                          Colors.orange
                        ], transform: GradientRotation(5.8)),
                        borderRadius: BorderRadius.circular(260)),
                  ),
                ),
                ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.all(10),
                    children: [
                      Row(
                        children: this
                            .searchResults
                            .keys
                            .map((e) => Row(
                                  children: [
                                    CategoryCard(
                                        currentStateKey, e, changeState, e, mp),
                                    SizedBox(width: 15),
                                  ],
                                ))
                            .toList(),
                      ),
                      CategoryCard(
                          currentStateKey, "", changeState, "AddCardUnique", mp,
                          isAddCard: true),
                    ]),
              ],
            ),
          ),
          SizedBox(
            height: 22,
          ),
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(40.0),
          //     ),
          //     child: Align(
          //       alignment: Alignment.center,
          //       child: Column(
          //         mainAxisSize: MainAxisSize.min,
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           TextField(
          //             controller: _searchController,
          //             style: TextStyle(fontSize: 17),
          //             onChanged: (value) {
          //               searchInList(
          //                   mp, _searchController.text, currentStateKey);
          //             },
          //             decoration: InputDecoration(
          //               contentPadding: EdgeInsets.symmetric(vertical: 16.0),
          //               hintText: "Search Passwords",
          //               border: InputBorder.none,
          //               prefixIcon: Icon(Icons.search),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          Expanded(
            child: Stack(
              children: [
                if (isReloading)
                  Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!isReloading)
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: CustomScrollView(
                    slivers: <Widget>[
                      SliverPadding(
                        padding: EdgeInsets.only(top: 20),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            Color itemColor = index.isOdd
                                ? Color.fromARGB(186, 255, 255, 255)
                                : Color.fromARGB(141, 51, 51, 52);
                            double itemHeight = index == 4 ? 60.0 : 60.0;
                            double gapHeight = 20.0;
                            double blurHeight = 40.0;

                            bool isTapped =
                                currentState[index]['isTapped'] ?? false;

                            return Padding(
                              padding: EdgeInsets.only(bottom: gapHeight),
                              child: GestureDetector(
                                onLongPress: () {
                                  HapticFeedback
                                      .mediumImpact(); // Trigger vibration

                                  TextEditingController textController =
                                      TextEditingController();

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Delete Confirmation"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            TextField(
                                              controller: textController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Type 'I want to delete' to confirm",
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("No"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              String enteredText =
                                                  textController.text
                                                      .trim()
                                                      .toLowerCase();
                                              if (enteredText ==
                                                  "i want to delete") {
                                                final CollectionReference
                                                    allOneDataCollection =
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            'AllOneData');
                                                final userId =
                                                    auth.currentUser?.uid;
                                                final String idToDelete =
                                                    currentState[index]['id'];

                                                try {
                                                  DocumentSnapshot doc =
                                                      await allOneDataCollection
                                                          .doc(userId)
                                                          .get();

                                                  if (doc.exists) {
                                                    Map<String, dynamic> data =
                                                        doc.data() as Map<
                                                            String, dynamic>;

                                                    if (data.containsKey(
                                                        currentStateKey)) {
                                                      List<dynamic>
                                                          currentStateList =
                                                          data[currentStateKey];

                                                      currentStateList
                                                          .removeWhere((item) =>
                                                              item['id'] ==
                                                              idToDelete);

                                                      await allOneDataCollection
                                                          .doc(userId)
                                                          .update({
                                                            currentStateKey:
                                                                currentStateList,
                                                          })
                                                          .then((value) => {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                        SnackBar(
                                                                  content: Text(
                                                                      "Data deleted from the Server."),
                                                                ))
                                                              })
                                                          .then((value) => {
                                                                setState(() {
                                                                  currentState
                                                                      .removeAt(
                                                                          index);
                                                                })
                                                              });
                                                    }
                                                  }
                                                } catch (error) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(
                                                        "Some Error Occured."),
                                                  ));
                                                }
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content:
                                                      Text("Deletion Stopped"),
                                                ));
                                              }
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Yes"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (builder) => AddTodoPage(
                                            propData: currentState[index],
                                            parentKey: currentStateKey,
                                            categorieslist: categories)),
                                    (route) => false,
                                  );

                                  setState(() {
                                    currentState[index]['isTapped'] = !isTapped;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: itemColor,
                                    border: Border.all(
                                      color: isTapped
                                          ? Colors.green
                                          : Colors.transparent,
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: itemHeight,
                                      alignment: Alignment.center,
                                      child: Stack(
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(width: 25),
                                              Container(
                                                width: 50,
                                                child: SvgPicture.asset(
                                                  currentState[index]
                                                      ['iconpath'],
                                                  width: 24,
                                                  height: 24,
                                                ),
                                              ),
                                              Container(
                                                width: 150,
                                                child: Text(
                                                  '${currentState[index]['name']}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: index.isEven
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            right: 45,
                                            top: 5,
                                            child: Opacity(
                                              opacity: 0.6,
                                              child: Text(
                                                '${currentState[index]['siteinfo']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: index.isEven
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 15,
                                            bottom: -1,
                                            child: Image.asset(
                                              'assets/opencard.png',
                                              width: 25,
                                              height: 25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: currentState.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(String text, String link) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(20),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white, // Text color
          ),
        ),
      ),
    );
  }

  void showDeleteConfirmationDialog(BuildContext context, int index,
      dynamic currentState, String currentStateKey, Function setStateCallback) {
    TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: "Type 'I want to delete' to confirm",
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () async {
                String enteredText = textController.text.trim().toLowerCase();
                if (enteredText == "i want to delete") {
                  final CollectionReference allOneDataCollection =
                      FirebaseFirestore.instance.collection('AllOneData');
                  final userId = auth.currentUser?.uid;
                  final String idToDelete = currentState[index]['id'];
                  try {
                    await allOneDataCollection.doc(userId).update({
                      currentStateKey: FieldValue.arrayRemove([
                        {'id': idToDelete}
                      ])
                    });

                    // setStateCallback(() {
                    //   currentState.removeAt(index);
                    // });

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Data deleted from Firebase."),
                    ));
                  } catch (error) {
                    print("Error deleting data from Firestore: $error");
                  }
                } else {
                  print("No");
                }
                Navigator.of(context).pop();
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String categoryName;
  Function changeState;
  final String keyV;
  final bool isAddCard;
  final String currentStateKey;
  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final Map<String, dynamic> mp;
  CategoryCard(this.currentStateKey, this.categoryName, this.changeState,
      this.keyV, this.mp,
      {this.isAddCard = false});

  String getSvgAssetForCategory(String category) {
    final categoryToSvgAsset = {
      'Social': 'assets/google.svg',
      'Accounts': 'assets/cardicon.svg',
      'Secret': 'assets/secreticon.svg',
    };
    return categoryToSvgAsset[category] ?? 'assets/random1.svg';
  }

  List<String> getSvgAssetForCategoryList(String category) {
    if (category == "Social") {
      return [
        "assets/google.svg",
        "assets/twittericon.svg",
        "assets/facebookicon.svg",
        "assets/instagramicon.svg"
      ];
    } else if (category == "Accounts") {
      return [
        "assets/cardicon.svg",
        "assets/accounticon.svg",
        "assets/bankicon.svg",
        "assets/passporticon.svg"
      ];
    } else if (category == "Secret") {
      return [
        "assets/secreticon.svg",
        "assets/secreticon2.svg",
        "assets/secreticon3.svg",
        "assets/secreticon4.svg"
      ];
    } else {
      return [
        "assets/random1.svg",
        "assets/random2.svg",
        "assets/random3.svg",
        "assets/random4.svg"
      ];
    }
  }

  bool isAlphaNumeric(String text) {
    RegExp alphaNumeric = RegExp(r'^[a-zA-Z0-9]+$');
    return alphaNumeric.hasMatch(text);
  }

  void _showAddCategoryDialog(BuildContext context) {
    String newCategoryName = '';

    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Category'),
          content: TextField(
            onChanged: (value) {
              if (isAlphaNumeric(value)) {
                newCategoryName = value;
              } else {}
            },
            decoration: InputDecoration(
              hintText: 'Enter a new Category Name',
            ),
            maxLength: 20,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                if (user != null) {
                  FirebaseFirestore.instance
                      .collection('AllOneData')
                      .doc(user.uid)
                      .update({
                    newCategoryName: [],
                  });
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => HomePage()),
                    (route) => false,
                  );
                } else {
                  print('User is not signed in.');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => LandingPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAddCard) {
      return GestureDetector(
        onTap: () {
          _showAddCategoryDialog(context);
        },
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(154, 0, 0, 0),
                offset: Offset(0, 3),
                blurRadius: 5,
              ),
            ],
            borderRadius: BorderRadius.circular(15),
            border:
                Border.all(color: Color.fromARGB(207, 54, 54, 54), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(11)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Color.fromARGB(128, 62, 63, 64),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: Color.fromARGB(207, 163, 162, 162),
                            size: 50,
                          ),
                        ),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color.fromARGB(207, 54, 54, 54),
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          changeState(keyV);
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              TextEditingController textController = TextEditingController();
              return AlertDialog(
                title: Text(
                    "Whole Data of '${currentStateKey}' Category will be Deleted !!!"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: "Type 'I want to delete' to confirm",
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("No"),
                  ),
                  TextButton(
                    onPressed: () async {
                      String enteredText =
                          textController.text.trim().toLowerCase();
                      if (enteredText == "i want to delete") {
                        final user = auth.currentUser;
                        final userId = user?.uid;
                        final CollectionReference categoriesCollection =
                            FirebaseFirestore.instance.collection('AllOneData');

                        try {
                          await categoriesCollection.doc(userId).update({
                            currentStateKey: FieldValue.delete(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "$currentStateKey and its data deleted from Server."),
                          ));
                          print(currentStateKey);
                          mp.remove(currentStateKey);
                        } catch (error) {
                          print(
                              "Error deleting $currentStateKey and its data from Server: $error");
                        }
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text("Yes"),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(154, 0, 0, 0),
                offset: Offset(0, 3),
                blurRadius: 5,
              ),
            ],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: keyV == currentStateKey
                  ? Color.fromARGB(152, 127, 232, 29)
                  : Color.fromARGB(207, 54, 54, 54),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(11)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Color.fromARGB(128, 62, 63, 64),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  // Center the entire content of the card
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            getSvgAssetForCategory(categoryName),
                            width: 25,
                            height: 25,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            categoryName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 60), // Add some spacing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            getSvgAssetForCategoryList(categoryName)[0],
                            width: 25,
                            height: 25,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          SvgPicture.asset(
                            getSvgAssetForCategoryList(categoryName)[1],
                            width: 25,
                            height: 25,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          SvgPicture.asset(
                            getSvgAssetForCategoryList(categoryName)[2],
                            width: 25,
                            height: 25,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          SvgPicture.asset(
                            getSvgAssetForCategoryList(categoryName)[3],
                            width: 25,
                            height: 25,
                          ),
                        ],
                      ),
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
}
