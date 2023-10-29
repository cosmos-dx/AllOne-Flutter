import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/pages/AllOneNotes.dart';
import 'package:planner_app/pages/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteViewer extends StatefulWidget {
  final String title;
  final dynamic content;

  NoteViewer({required this.title, required this.content});

  @override
  _NoteViewerState createState() => _NoteViewerState();
}

class _NoteViewerState extends State<NoteViewer> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title);
    contentController = TextEditingController(text: widget.content['content']);
  }

  Future<void> saveData(String title, String newContent) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final noteData = prefs.getString(title);

    Map<String, dynamic> noteMap = Map<String, dynamic>();
    if (noteData != null) {
      noteMap = json.decode(noteData);
    }

    noteMap['id'] = widget.content['id'];
    noteMap['content'] = newContent;
    final updatedData = json.encode(noteMap);
    await prefs.setString(title, updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 50,
        title: Row(
          children: [
            Text(
              "${widget.title}",
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
              Container(
                color: Color.fromARGB(134, 0, 0, 0),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title:',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Set text color to white
                        ),
                      ),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter a title',
                          hintStyle: TextStyle(color: Colors.white),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Content:',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(141, 0, 0, 0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: contentController,
                            expands: true,
                            maxLines: null,
                            style: TextStyle(
                                color: Color.fromARGB(171, 255, 255, 255)),
                            onChanged: (newContent) {
                              // Save the data when the content changes
                              saveData(titleController.text, newContent);
                            },
                            decoration: InputDecoration(
                              focusedBorder: InputBorder.none,
                              border: InputBorder.none,
                              hintText: 'Enter your notes',
                              hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255)),
                              contentPadding: EdgeInsets.all(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          onWillPop: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (builder) => AllOneNotes()),
            );
            return false;
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = auth.currentUser;
          final userId = user?.uid;

          String updatedTitle = titleController.text;
          String updatedContent = contentController.text;
          String id = widget.content['id'];

          CollectionReference notesCollection =
              FirebaseFirestore.instance.collection('AllOneNotes');

          DocumentReference documentReference = notesCollection.doc(userId);

          final updatedData = {
            updatedTitle: {
              'id': id,
              'content': updatedContent,
            }
          };

          try {
            await documentReference.update(updatedData);
            print('Document updated successfully');
          } catch (error) {
            print('Error updating document: $error');
          }

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (builder) => HomePage()),
              (route) => false);
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
