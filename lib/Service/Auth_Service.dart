import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planner_app/Service/EncryptionService.dart';
import 'package:planner_app/Service/FingerprintAuthentication.dart';
import 'package:planner_app/pages/HomePagePassword.dart';
import 'package:planner_app/pages/LandingPage.dart';
import 'package:uuid/uuid.dart';
import '../pages/HomePage.dart';

class AuthClass {
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );
  FirebaseAuth auth = FirebaseAuth.instance;
  final storage = new FlutterSecureStorage();

  Future<void> googleSignIn(BuildContext context) async {
    FingerPrintAuth fingerPrintAuth = FingerPrintAuth();
    await fingerPrintAuth.checkBiometricAvailability();
    try {
      GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );
        try {
          UserCredential userCredential =
              await auth.signInWithCredential(credential);
          storeTokenAndData(userCredential);
          await addDefaultNotes(userCredential);
          await addDefaultPass(userCredential);
          addDefaultDataToUserDatabase(userCredential).then((value) => {
                if (fingerPrintAuth.isBiometricAvaialbale)
                  {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (builder) => HomePage()),
                        (route) => false)
                  }
                else
                  {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => HomePagePassword()),
                        (route) => false)
                  }
              });
        } catch (e) {
          final snackbar = SnackBar(content: Text(e.toString()));
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
        }
      } else {
        final snackbar = SnackBar(content: Text("Not able to sign in"));
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      }
    } catch (e) {
      final snackbar = SnackBar(content: Text(e.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  Future<void> storeTokenAndData(UserCredential userCredential) async {
    await storage.write(
        key: "token", value: userCredential.credential?.token.toString());
    await storage.write(
        key: "userCredential", value: userCredential.credential.toString());
  }

  Future<void> storeTokenAndDataforPhone(UserCredential userCredential) async {
    await storage.write(key: "token", value: userCredential.user?.uid);
  }

  Future<String?> getToken() async {
    return await storage.read(key: "token");
  }

  Future<String?> getCred() async {
    return await storage.read(
      key: "userCredential",
    );
  }

  Future<String?> getcreddata() {
    return storage.read(
      key: "userCredential",
    );
  }

  Future<void> addDefaultPass(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user != Null) {
      final userId = user?.uid;
      final uuid = Uuid();
      final defaultDataNotes = {
        "password": {"pass"},
      };

      try {
        final firestore = FirebaseFirestore.instance;
        final collection2 = firestore.collection('AllOneLocalAuthPass');
        final userDocument2 = collection2.doc(userId);
        final userDocSnapshot2 = await userDocument2.get();
        if (!userDocSnapshot2.exists) {
          await userDocument2.set(defaultDataNotes);
        } else {}
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> addDefaultNotes(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user != Null) {
      final userId = user?.uid;
      final uuid = Uuid();
      final defaultDataNotes = {
        "Krishna": {
          "id": uuid.v4(),
          "content": """
        Krishna (/ˈkrɪʃnə/;[12] Sanskrit: कृष्ण, IAST: Kṛṣṇa [ˈkr̩ʂɳɐ]) is a major deity in Hinduism. He is worshipped as the eighth avatar of Vishnu and also as the Supreme God in his own right.[13] He is the god of protection, compassion, tenderness, and love;[14][1] and is one of the most popular and widely revered among Hindu divinities.[15] Krishna's birthday is celebrated every year by Hindus on Krishna Janmashtami according to the lunisolar Hindu calendar, which falls in late August or early September of the Gregorian calendar.[16][17][18]
        The anecdotes and narratives of Krishna's life are generally titled as Krishna Līlā. He is a central character in the Mahabharata, the Bhagavata Purana, the Brahma Vaivarta Purana, and the Bhagavad Gita, and is mentioned in many Hindu philosophical, theological, and mythological texts.[19] They portray him in various perspectives: as a god-child, a prankster, a model lover, a divine hero, and the universal supreme being.[20] His iconography reflects these legends, and shows him in different stages of his life, such as an infant eating butter, a young boy playing a flute, a young boy with Radha or surrounded by female devotees; or a friendly charioteer giving counsel to Arjuna.[21]
        The name and synonyms of Krishna have been traced to 1st millennium BCE literature and cults.[22] In some sub-traditions, like Krishnaism, Krishna is worshipped as Svayam Bhagavan (the Supreme God). These sub-traditions arose in the context of the medieval era Bhakti movement.[23][24] Krishna-related literature has inspired numerous performance arts such as Bharatanatyam, Kathakali, Kuchipudi, Odissi, and Manipuri dance.[25][26] He is a pan-Hindu god, but is particularly revered in some locations, such as Vrindavan in Uttar Pradesh,[27] Dwarka and Junagadh in Gujarat; the Jagannatha aspect in Odisha, Mayapur in West Bengal;[23][28][29] in the form of Vithoba in Pandharpur, Maharashtra, Shrinathji at Nathdwara in Rajasthan,[23][30] Udupi Krishna in Karnataka,[31] Parthasarathy in Tamil Nadu and in Aranmula, Kerala, and Guruvayoorappan in Guruvayoor in Kerala.[32] Since the 1960s, the worship of Krishna has also spread to the Western world and to Africa, largely due to the work of the International Society for Krishna
        """
        },
      };

      try {
        final firestore = FirebaseFirestore.instance;
        final collection2 = firestore.collection('AllOneNotes');
        final userDocument2 = collection2.doc(userId);
        final userDocSnapshot2 = await userDocument2.get();
        if (!userDocSnapshot2.exists) {
          await userDocument2.set(defaultDataNotes);
          print('Default data added to user database notes');
        } else {
          print('Default data already exists for this user. Skipping.');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> addDefaultDataToUserDatabase(
      UserCredential userCredential) async {
    final user = userCredential.user;
    DateTime now = DateTime.now();
    DateTime formattedTime = DateTime.timestamp();
    if (user != null) {
      final userId = user.uid;
      final uuid = Uuid();
      EncryptionService encryptionService = EncryptionService('${userId}');
      String password = encryptionService.encrypt("Keep Your Password Here");
      final defaultData = {
        "Social": [
          {
            "id": uuid.v4(),
            "name": "Facebook",
            "iconpath": "assets/facebookicon.svg",
            "password": password,
            "siteinfo": "www.facebook.com",
            "category": "Social",
            "sitename": "www.Facebook.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Google",
            "iconpath": "assets/google.svg",
            "password": password,
            "siteinfo": "www.google.com",
            "category": "Social",
            "sitename": "www.google.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Twitter",
            "iconpath": "assets/twittericon.svg",
            "password": password,
            "siteinfo": "www.twitter.com",
            "category": "Social",
            "sitename": "www.twitter.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Instagram",
            "iconpath": "assets/instagramicon.svg",
            "password": password,
            "siteinfo": "www.instagram.com",
            "category": "Social",
            "sitename": "www.instagram.com",
            "timestamp": formattedTime.toString()
          },
        ],
        "Accounts": [
          {
            "id": uuid.v4(),
            "name": "SBI",
            "iconpath": "assets/bankicon.svg",
            "password": password,
            "siteinfo": "www.sbi.co.in",
            "category": "Accounts",
            "sitename": "www.statebankofindia.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "HDFC",
            "iconpath": "assets/cardicon.svg",
            "password": password,
            "siteinfo": "www.hdfc.com",
            "category": "Accounts",
            "sitename": "www.hdfc.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Passport",
            "iconpath": "assets/passporticon.svg",
            "password": password,
            "siteinfo": "www.passport.in",
            "category": "Accounts",
            "sitename": "www.passport.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Accounting",
            "iconpath": "assets/accounticon.svg",
            "password": password,
            "siteinfo": "www.metamask.com",
            "category": "Accounts",
            "sitename": "www.blockchain.com",
            "timestamp": formattedTime.toString()
          },
        ],
        "Secret": [
          {
            "id": uuid.v4(),
            "name": "Secret1",
            "iconpath": "assets/secreticon.svg",
            "password": password,
            "siteinfo": "My Information",
            "category": "Secret",
            "sitename": "www.start.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Secret2",
            "iconpath": "assets/secreticon2.svg",
            "password": password,
            "siteinfo": "Peronal Information",
            "category": "Secret",
            "sitename": "www.Mask.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Secret3",
            "iconpath": "assets/secreticon3.svg",
            "password": password,
            "siteinfo": "I a'nt gonna tell",
            "category": "Secret",
            "sitename": "www.WikiPedia.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Secret4",
            "iconpath": "assets/secreticon4.svg",
            "password": password,
            "siteinfo": "Thats it",
            "category": "Secret",
            "sitename": "www.Facebook.com",
            "timestamp": formattedTime.toString()
          },
        ],
        "HealSync": [
          {
            "id": uuid.v4(),
            "name": "Dairy",
            "iconpath": "assets/random1.svg",
            "password": password,
            "siteinfo": "Dairy",
            "category": "HealSync",
            "sitename": "www.countrydelight.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Grossary",
            "iconpath": "assets/random2.svg",
            "password": password,
            "siteinfo": "Grossary",
            "category": "HealSync",
            "sitename": "www.jiomart.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Finance",
            "iconpath": "assets/random3.svg",
            "password": password,
            "siteinfo": "Hisab",
            "category": "HealSync",
            "sitename": "www.paytm.com",
            "timestamp": formattedTime.toString()
          },
          {
            "id": uuid.v4(),
            "name": "Addhar",
            "iconpath": "assets/random4.svg",
            "password": password,
            "siteinfo": "Aadhar card",
            "category": "HealSync",
            "sitename": "www.uidai.in",
            "timestamp": formattedTime.toString()
          },
        ],
      };

      try {
        final firestore = FirebaseFirestore.instance;
        final collection = firestore.collection('AllOneData'); 
        final userDocument = collection.doc(userId);
        final userDocSnapshot = await userDocument.get();
        if (!userDocSnapshot.exists) {
          await userDocument.set(defaultData);
          print('Default data added to user database');
        } else {
          print('Default data already exists for this user. Skipping.');
        }
      } catch (e) {
        print('Error adding default data: $e');
      }
    }
  }

  Future<void> verifyPhoneNumber(
      String phoneNumber, BuildContext context, Function setData) async {
    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential phoneAuthCredential) async {
      showSnackBar(context, "Verification Completed");
    };
    PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException exception) {
      showSnackBar(context, exception.toString());
    };
    PhoneCodeSent codeSent =
        (String verificationID, [int? forceResendingtoken]) {
      showSnackBar(context, "Verification Code Sent to Phone");
      setData(verificationID);
    };
    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationID) {
      showSnackBar(context, "Time Out");
    };
    try {
      await auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await auth.signOut();
      storage.delete(key: "token");

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (builder) => LandingPage()),
          (route) => false);
      showSnackBar(context, "Logged Out");
    } catch (e) {
      final snackbar = SnackBar(content: Text(e.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  Future<void> signInwithPhoneNumber(
      String verificationId, String smsCode, BuildContext context) async {
    FingerPrintAuth fingerPrintAuth = FingerPrintAuth();

    try {
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);

      UserCredential userCredential =
          await auth.signInWithCredential(credential);
      await storeTokenAndDataforPhone(userCredential);
      await addDefaultNotes(userCredential);
      await addDefaultPass(userCredential);
      await addDefaultDataToUserDatabase(userCredential);
      await fingerPrintAuth.checkBiometricAvailability();
      if (fingerPrintAuth.isBiometricAvaialbale) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (builder) => HomePage()),
            (route) => false);
        showSnackBar(context, "Logged In");
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (builder) => HomePagePassword()),
            (route) => false);
        showSnackBar(context, "Logged In");
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> startdecryption(
      String verificationId, String smsCode, BuildContext context) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);

      showSnackBar(context, "Starting Decryption !!!");
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
