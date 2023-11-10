import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class FingerPrintAuth {
  late final LocalAuthentication fingerPrintauth;
  bool supportState = false;
  bool isBiometricAvaialbale = false;

  FingerPrintAuth() {
    fingerPrintauth = LocalAuthentication();
    checkBiometricAvailability();
  }
  Future<void> checkBiometricAvailability() async {
    try {
      bool hasBiometrics = await fingerPrintauth.canCheckBiometrics;
      if (hasBiometrics) {
        List<BiometricType> availableBiometrics =
            await fingerPrintauth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          isBiometricAvaialbale = true;
        }
      }
    } on PlatformException catch (e) {
      print("Error checking biometric availability: $e");
    }
  }

  Future<void> authenticateFingers() async {
    try {
      bool authenticated = await fingerPrintauth.authenticate(
        localizedReason: 'Verify is That You !!!',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated) {
        print("Authentication successful");
      } else
        authenticateFingers();
    } on PlatformException catch (e) {
      print(e);
    }
  }
}

late final FingerPrintAuth fingerPrintAuth = FingerPrintAuth();
