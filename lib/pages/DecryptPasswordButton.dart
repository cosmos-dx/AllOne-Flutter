import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/Service/EncryptionService.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

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
  final LocalAuthentication fingerprintauth = LocalAuthentication();

  Future<bool> isSensorAvilable() async {
    final bool canAuthenticateWithBiometrics =
        await fingerprintauth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics ||
        await fingerprintauth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> isAuthenticated() async {
    bool didAuthenticate = false;
    try {
      didAuthenticate = await fingerprintauth.authenticate(
          localizedReason: 'Please authenticate to show account balance',
          options: const AuthenticationOptions(useErrorDialogs: false));
      // ···
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        // Add handling of no hardware here.
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        // ...
      } else {
        // ...
      }
    }
    // final bool didAuthenticate = await fingerprintauth.authenticate(
    //     localizedReason: 'Please authenticate to show account balance',
    //     options: const AuthenticationOptions(biometricOnly: true));
    return didAuthenticate;
  }

  @override
  Widget build(BuildContext context) {
    String initialencryptedpasswordserver = widget.encryptedpasswordserver;
    final user = auth.currentUser;
    final userid1 = user?.email ?? '';
    final userid2 = user?.phoneNumber ?? '';
    String userID = '';

    if (userid1.isNotEmpty && userid2.isEmpty) {
      userID = userid1;
    } else if (userid1.isEmpty && userid2.isNotEmpty) {
      userID = userid2;
    } else {
      print("Gola");
    }

    return InkWell(
        onTap: () async {
          if (userid2.isNotEmpty) {
            // If userID is a phone number, request OTP verification
            await authClass.verifyPhoneNumber(userID, context, setData);
            _showOTPDialog(context);
          } else {
            // if (await isSensorAvilable()) {
            //   if (await isAuthenticated()) {
            //     decryptPassword();
            //   }
            //   showSnackBar(context, "FingerPrint Not Matched");
            // } else {
            //   showSnackBar(context, "Sensors are not Available");
            // }
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
        ));
  }

  void setData(verificationID) {
    setState(() {
      verificationIDFinal = verificationID;
    });
  }

  void _showOTPDialog(BuildContext context) {
    TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter OTP"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Verify OTP"),
              onPressed: () {
                String enteredOTP = otpController.text;
                setState(() {
                  smscode = enteredOTP;
                });
                verifywithPhoneNumber(verificationIDFinal, smscode, context);
              },
            ),
          ],
        );
      },
    );
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
