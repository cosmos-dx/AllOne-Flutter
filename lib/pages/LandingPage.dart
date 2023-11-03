import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/pages/HomePage.dart';
import 'package:planner_app/pages/PhoneAuthPage.dart';
import 'package:planner_app/pages/SignUPPage.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  firebase_auth.FirebaseAuth firebaseAuth = firebase_auth.FirebaseAuth.instance;
  bool circular = false;
  AuthClass authClass = AuthClass();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Landing4.png',
                height: 400,
                width: 400,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            "AllOne",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold),
                          ),
                          Image.asset(
                            'assets/Alloneicon.png',
                            width: 50,
                            height: 50,
                          ),
                        ],
                      ),
                      SizedBox(height: 62),
                      Text(
                        "Here we keep your all passwords Safe !!!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 22),
              colorButton(context)
            ],
          ),
        ),
      ),
    );
  }

  bool buttonTapped = false; // Track button tap state

  Widget colorButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          buttonTapped = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          buttonTapped = false;
        });
      },
      onTapCancel: () {
        setState(() {
          buttonTapped = false;
        });
      },
      onTap: () {
        // Handle button click here
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (builder) => SignUpPage()),
            (route) => false);
      },
      child: AnimatedContainer(
        width: MediaQuery.of(context).size.width - 90,
        height: 60,
        duration: Duration(milliseconds: 10), // Animation duration
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color:
              buttonTapped ? Color.fromARGB(255, 255, 255, 255) : Colors.black,
          border: Border.all(
            color: Colors.grey,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Let's Get Started",
                style: TextStyle(
                  color: buttonTapped ? Colors.black : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 40),
              buttonTapped
                  ? SvgPicture.asset(
                      'assets/arrow.svg',
                      width: 30,
                      height: 30,
                    )
                  : ClipOval(
                      child: Image.asset(
                        'assets/arrow2.gif',
                        width: 30,
                        height: 30,
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
