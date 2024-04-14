import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:planner_app/Service/EncryptionService.dart';
import 'package:planner_app/pages/DecryptPasswordButton.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'HomePage.dart';

String generateRandomKey() {
  final random = Random.secure();
  final keyBytes = Uint8List(32);
  for (int i = 0; i < keyBytes.length; i++) {
    keyBytes[i] = random.nextInt(256);
  }
  return base64Url.encode(keyBytes);
}

class AddTodoPage extends StatefulWidget {
  final dynamic propData;
  final dynamic parentKey;
  final dynamic categorieslist;
  AddTodoPage({Key? key, this.propData, this.parentKey, this.categorieslist})
      : super(key: key);

  @override
  _AddTodoPageState createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  TextEditingController _displayName = TextEditingController();
  TextEditingController _datainfo = TextEditingController();
  TextEditingController _sitename = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _iconpath = TextEditingController();
  TextEditingController _titletask = TextEditingController();
  TextEditingController _decriptioncontroller = TextEditingController();
  AuthClass _authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isDataAvailable = false;
  bool isDecryptionClicked = false;
  String type = "";
  String temp = "";
  String category = "";
  String iconPath = "";
  bool allowSpecialCharacters = false;
  bool allowNumbers = false;
  bool isPropdata = true;
  double passwordLength = 8.0;
  String selectedCategory = '';
  String selectedIconPath = '';
  bool isLoading = false;

  List<Map<String, dynamic>> iconList = [
    {"name": "Icon 1", "path": "assets/google.svg"},
    {"name": "Icon 2", "path": "assets/cardicon.svg"},
    {"name": "Icon 3", "path": "assets/facebookicon.svg"},
    {"name": "Icon 4", "path": "assets/instagramicon.svg"},
    {"name": "Icon 5", "path": "assets/reddit.svg"},
    {"name": "Icon 6", "path": "assets/twittericon.svg"},
    {"name": "Icon 7", "path": "assets/visa.svg"},
    {"name": "Icon 8", "path": "assets/vehicle1.svg"},
    {"name": "Icon 9", "path": "assets/quora.svg"},
    {"name": "Icon 10", "path": "assets/phone.svg"},
    {"name": "Icon 11", "path": "assets/gmail.svg"},
    {"name": "Icon 12", "path": "assets/linkedin.svg"},
    {"name": "Icon 13", "path": "assets/github.svg"},
    {"name": "Icon 14", "path": "assets/food.svg"},
    {"name": "Icon 15", "path": "assets/arrow.svg"},
    {"name": "Icon 16", "path": "assets/amazon.svg"},
    {"name": "Icon 17", "path": "assets/accounticon.svg"},
    {"name": "Icon 18", "path": "assets/bankicon.svg"},
    {"name": "Icon 19", "path": "assets/browser1.svg"},
    {"name": "Icon 20", "path": "assets/browser2.svg"},
    {"name": "Icon 21", "path": "assets/cardicon.svg"},
    {"name": "Icon 22", "path": "assets/dropbox.svg"},
    {"name": "Icon 23", "path": "assets/laptop1.svg"},
    {"name": "Icon 24", "path": "assets/mark.svg"},
    {"name": "Icon 25", "path": "assets/microsoft.svg"},
    {"name": "Icon 26", "path": "assets/music1.svg"},
    {"name": "Icon 27", "path": "assets/music2.svg"},
    {"name": "Icon 28", "path": "assets/passporticon.svg"},
    {"name": "Icon 29", "path": "assets/random1.svg"},
    {"name": "Icon 30", "path": "assets/random2.svg"},
    {"name": "Icon 31", "path": "assets/random3.svg"},
    {"name": "Icon 32", "path": "assets/random4.svg"},
    {"name": "Icon 33", "path": "assets/sheet.svg"},
    {"name": "Icon 34", "path": "assets/secreticon.svg"},
    {"name": "Icon 35", "path": "assets/secreticon2.svg"},
    {"name": "Icon 36", "path": "assets/secreticon3.svg"},
    {"name": "Icon 37", "path": "assets/secreticon4.svg"},
    {"name": "Icon 38", "path": "assets/like.svg"},
  ];

  void generatePassword(bool regenerate) {
    if (regenerate || _password.text.isEmpty) {
      String chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

      if (allowSpecialCharacters) {
        chars += "!@#\$%^&*()-_=+[]{}|;:'\",.<>/?";
      }

      if (allowNumbers) {
        chars += "0123456789";
      }

      Random random = Random();
      String password = '';

      for (int i = 0; i < passwordLength; i++) {
        password += chars[random.nextInt(chars.length)];
      }

      _password.text = password;
    } else if (!regenerate) {
      _password.text = '';
    }
  }

  void selectIcon(String path) {
    setState(() {
      if (selectedIconPath == path) {
        selectedIconPath = '';
        _iconpath.text = "";
      } else {
        selectedIconPath = path;
        _iconpath.text = path;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    final passingData = widget.propData;
    if (passingData != null && passingData.toString() != '{}') {
      _displayName.text = passingData['name'];
      _datainfo.text = passingData['siteinfo'];
      _iconpath.text = passingData['iconpath'];
      _password.text = passingData['password'];
      _sitename.text = passingData['sitename'];
      selectedCategory = widget.parentKey;
      selectedIconPath = widget.propData['iconpath'];
      isDataAvailable = true;
    } else {
      isPropdata = false;
      selectedIconPath = '';
      isDecryptionClicked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final widthi = MediaQuery.of(context).size.width;
    final dynamic passingData = widget.propData;
    final dynamic categories = widget.categorieslist;

    return Stack(
      children: [
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
        Scaffold(
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Colors.black,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  IconButton(
                    onPressed: () {},
                    icon: InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (builder) => HomePage()),
                          (route) => false,
                        );
                      },
                      child: Icon(
                        CupertinoIcons.arrow_left,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create",
                          style: TextStyle(
                            fontSize: 33,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "New Password",
                          style: TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 25),
                        text_label("Display Name"),
                        SizedBox(height: 5),
                        textItem("Set Site Display Name", _displayName, false,
                            isDecryptionClicked),
                        SizedBox(
                          height: 10,
                        ),
                        text_label("SiteName/Data Info"),
                        SizedBox(height: 5),
                        textItem(
                            "www.example.com Or Small brief about the Site/Data",
                            _datainfo,
                            false,
                            isDecryptionClicked),
                        SizedBox(
                          height: 10,
                        ),
                        text_label("UserName"),
                        SizedBox(
                          height: 5,
                        ),
                        textItem(
                            "Username", _sitename, false, isDecryptionClicked),
                        SizedBox(
                          height: 10,
                        ),
                        text_label("Password"),
                        SizedBox(
                          height: 5,
                        ),
                        textItem(
                            "Password", _password, false, isDecryptionClicked),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 5.0, sigmaY: 5.0),
                                      child: StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            backgroundColor: Color.fromARGB(
                                                    170, 110, 108, 108)
                                                .withOpacity(0.7),
                                            title: Text("Password Options",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                customSwitchListTile(
                                                  title:
                                                      "Include Special Characters",
                                                  value: allowSpecialCharacters,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      allowSpecialCharacters =
                                                          value;
                                                    });
                                                  },
                                                ),
                                                customSwitchListTile(
                                                  title: "Include Numbers",
                                                  value: allowNumbers,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      allowNumbers = value;
                                                    });
                                                  },
                                                ),
                                                Text(
                                                    "Password Length: ${passwordLength.toInt()}",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                SliderTheme(
                                                  data: SliderTheme.of(context)
                                                      .copyWith(
                                                    trackHeight: 8.0,
                                                    thumbColor: Colors.black,
                                                    activeTrackColor:
                                                        Colors.white,
                                                  ),
                                                  child: Slider(
                                                    value: passwordLength,
                                                    min: 8,
                                                    max: 20,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        passwordLength = value;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color.fromARGB(
                                                            255, 0, 0, 0),
                                                  ),
                                                  onPressed: () {
                                                    generatePassword(true);
                                                    Navigator.pop(context);
                                                  },
                                                  child:
                                                      Text("Generate Password"),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text("Generate Password"),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                        text_label("Password Icons"),
                        SizedBox(
                          height: 10,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: () {
                              List<Widget> iconWidgets = [];

                              iconList.forEach((icon) {
                                bool isSelected =
                                    selectedIconPath == icon["path"];

                                if (isPropdata &&
                                    icon["path"] == passingData["iconpath"]) {
                                  isSelected = true;
                                }

                                final iconWidget = GestureDetector(
                                  onTap: () {
                                    selectIcon(icon["path"]);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.white,
                                    ),
                                    child: SvgPicture.asset(
                                      icon["path"],
                                      width: isSelected ? 48 : 24,
                                      height: 24,
                                    ),
                                  ),
                                );

                                iconWidgets.add(iconWidget);
                              });

                              return List.generate(iconWidgets.length, (index) {
                                final widget = iconWidgets[index];
                                if (index != iconWidgets.length - 1) {
                                  // Add spacing between icons except for the last one
                                  return Row(
                                    children: <Widget>[
                                      widget,
                                      SizedBox(width: 16),
                                    ],
                                  );
                                } else {
                                  return widget;
                                }
                              });
                            }(),
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        text_label("Category"),
                        SizedBox(
                          height: 12,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: isLoading
                              ? CircularProgressIndicator()
                              : Row(
                                  children: categories.map<Widget>((category) {
                                    bool isCategoryMatch =
                                        selectedCategory == category;

                                    return Row(
                                      children: [
                                        chidData(category, isCategoryMatch),
                                        SizedBox(width: 20),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        isDecryptionClicked
                            ? SizedBox(
                                height: 0,
                              )
                            : DecryptPasswordButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "sdfsdf",
                                        style: TextStyle(color: Colors.amber),
                                      ),
                                    ),
                                  );
                                },
                                encryptedpasswordserver: _password.text,
                                onDecrypted: handleDecryptedPassword,
                              ),
                        SizedBox(
                          height: 15,
                        ),
                        isDataAvailable
                            ? SizedBox(
                                height: 15,
                              )
                            : buttonadddata(context, passingData)
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget customSwitchListTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color.fromARGB(255, 255, 255, 255),
            activeTrackColor: Color.fromARGB(255, 0, 0, 0),
            inactiveThumbColor: Color.fromARGB(255, 0, 0, 0),
            inactiveTrackColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ],
      ),
    );
  }

  Widget chidData(String chiptext, bool flag) {
    return InkWell(
      onTap: () {
        setState(() {
          if (selectedCategory == chiptext) {
            selectedCategory = '';
          } else {
            selectedCategory = chiptext;
          }
        });
      },
      child: Chip(
        backgroundColor: flag
            ? Color.fromARGB(255, 255, 255, 255)
            : Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: flag ? Colors.green : Colors.white,
            width: 2.0,
          ),
        ),
        label: Text(
          chiptext,
          style: TextStyle(
            color: flag
                ? Color.fromARGB(255, 56, 54, 54)
                : Color.fromARGB(255, 230, 230, 230),
            fontSize: flag ? 13 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 3.8),
      ),
    );
  }

  Widget textItem(String labeltext, TextEditingController controller,
      bool obsecuretext, bool isDecryptionClicked) {
    bool isDisplayName = false;
    if (controller == _displayName) {
      isDisplayName = true;
    }

    return Container(
      width: MediaQuery.of(context).size.width - 70,
      height: 55,
      child: TextField(
        controller: controller,
        obscureText: obsecuretext,
        enabled: isDecryptionClicked,
        style: TextStyle(
          fontSize: 17,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: labeltext,
          labelStyle: TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 214, 214, 214),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              width: 1.5,
              color: Color.fromARGB(111, 19, 255, 7),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              width: 1.5,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget text_label(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16.5,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  bool isAlphaNumeric(String text) {
    RegExp alphaNumericWithSpaces = RegExp(r'^[a-zA-Z0-9 ]+$');
    return alphaNumericWithSpaces.hasMatch(text);
  }

  Widget buttonadddata(BuildContext context, dynamic passingData) {
    DateTime now = DateTime.now();
    String formattedTime = DateFormat.Hm().format(now);

    bool isClicked = false;
    final user = auth.currentUser;
    final uuid = Uuid();
    final userid = user?.uid;
    String encryptedPassword = '';

    if (_password.text.isNotEmpty) {
      EncryptionService encryptionService = EncryptionService('${userid}');
      encryptedPassword = encryptionService.encrypt(_password.text);
    }
    return GestureDetector(
      onTap: () async {
        final connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.none) {
          showSnackBar(context, "Connect To A Network First");
        } else {
          if (_displayName.text.isEmpty ||
              _datainfo.text.isEmpty ||
              _sitename.text.isEmpty ||
              _password.text.isEmpty) {
            showSnackBar(context, "Empty Field Not Allowed");
          } else if (_iconpath.text.isEmpty) {
            showSnackBar(context, "Pick an Icon");
          } else {
            setState(() {
              isLoading = true;
              isDataAvailable = true;
            });
            if (!isAlphaNumeric(_displayName.text)) {
              showSnackBar(
                  context, "Display Name cannot contain special Chars");
            }

            if (user != null) {
              final temp = user.uid;
              final data = {
                "id": uuid.v4(),
                "name": _displayName.text,
                "siteinfo": _datainfo.text,
                "sitename": _sitename.text,
                "password": encryptedPassword.isEmpty
                    ? _password.text
                    : encryptedPassword,
                "iconpath": _iconpath.text,
                "timestamp": formattedTime,
                "category": selectedCategory != widget.parentKey
                    ? selectedCategory
                    : widget.parentKey,
              };

              final docRef = FirebaseFirestore.instance
                  .collection("AllOneData")
                  .doc(user.uid);

              if (selectedCategory == widget.parentKey) {
                final existingData = await docRef.get();
                final dataArray = existingData.data()?[widget.parentKey] ?? [];
                final dataToUpdate = dataArray.firstWhere(
                  (item) => item['id'] == passingData['id'],
                  orElse: () => null,
                );

                if (dataToUpdate != null) {
                  dataArray.remove(dataToUpdate);
                  dataArray.add(data);
                  await docRef.update({
                    widget.parentKey: dataArray,
                  });
                } else {
                  await docRef.update({
                    widget.parentKey: FieldValue.arrayUnion([data]),
                  });
                  // showSnackBar(context, "Data with the provided ID not found.");
                }
              } else if (selectedCategory == '') {
                await docRef.update({
                  widget.parentKey: FieldValue.arrayUnion([data]),
                });
              } else {
                final idToRemove = passingData['id'];
                final existingData = await docRef.get();
                final dataArray = existingData.data()?[widget.parentKey] ?? [];
                final updatedDataArray = dataArray
                    .where((item) => item['id'] != idToRemove)
                    .toList();

                await docRef.update({
                  selectedCategory: FieldValue.arrayUnion([data]),
                });

                await docRef.update({
                  widget.parentKey: updatedDataArray,
                });
              }
              setState(() {
                isLoading = false;
                isClicked = true;
              });
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (builder) => HomePage()),
                (route) => false,
              );
              showSnackBar(context, "Your Data is Now Secured");
            }
          }
          setState(() {
            isClicked = true;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: 56,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromARGB(217, 255, 255, 255),
          border: Border.all(
            color: Color.fromARGB(255, 114, 114, 114),
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/lock.svg'),
                SizedBox(
                  width: 20,
                ),
                Text(
                  "Encrypt Password",
                  style: TextStyle(
                    color: Color.fromARGB(255, 46, 46, 46),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void authAction() async {
    final credentials = await _authClass.getToken();

    if (credentials != null) {
      await FlutterSecureStorage().write(
        key: _sitename.text,
        value: _password.text,
      );
    }
  }

  void handleDecryptedPassword(String decryptedPassword) {
    setState(() {
      _password.text = decryptedPassword;
      isDecryptionClicked = true;
      isDataAvailable = false;
    });
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
