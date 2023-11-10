import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/Service/FingerprintAuthentication.dart';
import 'package:planner_app/pages/AddToDo.dart';
import 'package:planner_app/pages/HomePage.dart';
import 'package:planner_app/pages/HomePagePassword.dart';
import 'package:planner_app/pages/LandingPage.dart';
import 'package:planner_app/pages/SignUPPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget currentPage = LandingPage();
  AuthClass authClass = AuthClass();
  FingerPrintAuth fingerPrintAuth = FingerPrintAuth();
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    String? token = await authClass.getToken();
    await fingerPrintAuth.checkBiometricAvailability();
    if (token != null) {
      if (fingerPrintAuth.isBiometricAvaialbale) {
        setState(() {
          currentPage = HomePage();
        });
      } else {
        setState(() {
          currentPage = HomePagePassword();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: currentPage,
    );
  }
}
