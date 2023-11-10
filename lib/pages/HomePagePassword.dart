import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/pages/HomePage.dart';

class HomePagePassword extends StatefulWidget {
  const HomePagePassword({Key? key}) : super(key: key);

  @override
  State<HomePagePassword> createState() => _HomePagePasswordState();
}

class _HomePagePasswordState extends State<HomePagePassword> {
  TextEditingController _localPass = TextEditingController();
  bool isTyping = false;
  String originalpassword = "";

  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getPassword();
    _localPass.addListener(_onTextChanged);
  }

  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  hintText: 'Enter Old Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  hintText: 'Enter New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                String oldPassword = _oldPasswordController.text;
                String newPassword = _newPasswordController.text;

                if (oldPassword.isNotEmpty && newPassword.isNotEmpty) {
                  if (originalpassword == oldPassword) {
                    final user = auth.currentUser;
                    if (user != null) {
                      final userId = user.uid;
                      final firestore = FirebaseFirestore.instance;
                      final document = firestore
                          .collection('AllOneLocalAuthPass')
                          .doc(userId);

                      document.get().then(
                          (DocumentSnapshot<Map<String, dynamic>> snapshot) {
                        if (snapshot.exists) {
                          List<dynamic>? passwords =
                              snapshot.data()?['password'];

                          if (passwords != null && passwords.isNotEmpty) {
                            passwords[0] = newPassword;
                            document.update({'password': passwords}).then((_) {
                              getPassword();
                              _oldPasswordController.text = '';
                              _newPasswordController.text = '';
                              print('Password updated successfully.');
                            }).catchError((error) {
                              print('Error updating password: $error');
                            });
                          } else {
                            print('No passwords found in the document.');
                          }
                        } else {
                          print('Document does not exist.');
                        }
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password Changed!'),
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Password Not Matched. Enter correct password!'),
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  }
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Both fields are required!'),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void getPassword() {
    final user = auth.currentUser;
    if (user != null) {
      final userId = user.uid;
      final firestore = FirebaseFirestore.instance;
      final document = firestore.collection('AllOneLocalAuthPass').doc(userId);

      document.get().then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.exists) {
          List<dynamic>? passwords = snapshot.data()?['password'];

          if (passwords != null && passwords.isNotEmpty) {
            setState(() {
              originalpassword = passwords[0];
            });
          } else {
            print('No passwords found in the document.');
          }
        } else {
          print('Document does not exist.');
        }
      }).catchError((error) {
        print('Error getting document: $error');
      });
    }
  }

  void _onTextChanged() {
    setState(() {
      isTyping = _localPass.text.isNotEmpty;
    });

    if (originalpassword == _localPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password matched!'),
          duration: Duration(milliseconds: 500),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (builder) => HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerSize = 300.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height / 4 - containerSize,
              left: MediaQuery.of(context).size.width / 4 - containerSize / 2,
              width: containerSize - 100,
              height: containerSize,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                    ],
                    transform: GradientRotation(6.8),
                  ),
                  borderRadius: BorderRadius.circular(containerSize / 2),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - containerSize / 2,
              left: MediaQuery.of(context).size.width / 2 - containerSize / 2,
              width: containerSize,
              height: containerSize,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                    ],
                    transform: GradientRotation(5.8),
                  ),
                  borderRadius: BorderRadius.circular(containerSize / 2),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height / 4 - containerSize,
              right: MediaQuery.of(context).size.width / 4 - containerSize / 2,
              width: containerSize - 100,
              height: containerSize,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                    ],
                    transform: GradientRotation(3.8),
                  ),
                  borderRadius: BorderRadius.circular(containerSize / 2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(181, 255, 255, 255),
                  borderRadius: BorderRadius.circular(75),
                ),
              ),
            ),
            Center(
              child: Container(
                width: containerSize + 50,
                height: containerSize - 100,
                decoration: BoxDecoration(
                  color: Color.fromARGB(128, 62, 63, 64),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isTyping ? 'Never Ever Forget Your Pass' : "Password",
                      style: TextStyle(
                        color: isTyping
                            ? Color.fromARGB(239, 255, 24, 3)
                            : Color.fromARGB(255, 255, 255, 255),
                        fontSize: 20,
                        fontWeight:
                            isTyping ? FontWeight.bold : FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _localPass,
                      autofillHints: [_localPass.text],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "Default Password is 'pass'",
                        hintStyle: TextStyle(color: Colors.amber),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            isTyping ? FontStyle.normal : FontStyle.italic,
                        color: isTyping
                            ? const Color.fromARGB(255, 255, 255, 255)
                            : const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    SizedBox(height: 30),
                    InkWell(
                      onTap: () {
                        _showChangePasswordDialog();
                      },
                      child: Text(
                        "Want New Password ?",
                        style: TextStyle(
                          color: isTyping
                              ? Color.fromARGB(238, 49, 255, 3)
                              : Color.fromARGB(255, 176, 25, 25),
                          fontSize: 14,
                          fontWeight:
                              isTyping ? FontWeight.bold : FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
