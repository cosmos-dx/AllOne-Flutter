import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/Service/EncryptionService.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:planner_app/Service/FingerprintAuthentication.dart';

class DecryptPasswordButton extends StatefulWidget {
  final Function onPressed;
  final Function(String) onDecrypted;
  final String encryptedpasswordserver;

  DecryptPasswordButton(
      {required this.onPressed,
      required this.onDecrypted,
      required this.encryptedpasswordserver});

  @override
  _DecryptPasswordButtonState createState() => _DecryptPasswordButtonState();
}

class _DecryptPasswordButtonState extends State<DecryptPasswordButton> {
  AuthClass authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String verificationIDFinal = "";
  String smscode = "";
  late final FingerPrintAuth fingerPrintAuth = FingerPrintAuth();

  @override
  Widget build(BuildContext context) {
    String initialencryptedpasswordserver = widget.encryptedpasswordserver;
    final user = auth.currentUser;

    return InkWell(
      onTap: () async {
        await fingerPrintAuth.checkBiometricAvailability();
        if (fingerPrintAuth.isBiometricAvaialbale) {
          fingerPrintAuth
              .authenticateFingers()
              .then((value) => decryptPassword());
        } else {
          decryptPassword();
        }
      },
      child: Container(
        height: 56,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromARGB(217, 255, 255, 255), // Background color
          border: Border.all(
            color: Color.fromARGB(255, 114, 114, 114), // Border color
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/unlock.svg'),
                SizedBox(
                  width: 20,
                ),
                Text(
                  "Decrypt Password",
                  style: TextStyle(
                    color: Color.fromARGB(255, 46, 46, 46), // Text color
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

  void setData(verificationID) {
    setState(() {
      verificationIDFinal = verificationID;
    });
  }

  void verifywithPhoneNumber(
      String verificationId, String smsCode, BuildContext context) async {
    try {
      EncryptionService encryptionService =
          EncryptionService('${auth.currentUser?.uid}');
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        String decryptedPassword =
            encryptionService.decrypt(widget.encryptedpasswordserver);
        widget.onDecrypted(decryptedPassword);
        showSnackBar(context, "Decrypted !!!");
        Navigator.of(context).pop();
      } else {
        showSnackBar(context, "SMS code verification failed");
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void decryptPassword() {
    try {
      EncryptionService encryptionService =
          EncryptionService('${auth.currentUser?.uid}');
      String decryptedPassword =
          encryptionService.decrypt(widget.encryptedpasswordserver);
      widget.onDecrypted(decryptedPassword);
      showSnackBar(context, "Decrypted !!!");
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
