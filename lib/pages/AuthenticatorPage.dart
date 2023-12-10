import 'dart:async';
import 'dart:math';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:planner_app/pages/HomePage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp/totp.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:timer_builder/timer_builder.dart';

class AuthenticatorPage extends StatefulWidget {
  const AuthenticatorPage({super.key});

  @override
  _AuthenticatorPageState createState() => _AuthenticatorPageState();
}

class _AuthenticatorPageState extends State<AuthenticatorPage> {
  final secretKey = "JBSWY3DPEHPK3PXP";
  late List<String> currentTOTPs;

  ScanResult? scanResult;
  Timer? _timer;
  int timerCountdown = 0;
  TextEditingController keyController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  double _percentTimer = 1.0;
  final _flashOnController = TextEditingController(text: 'Flash on');
  final _flashOffController = TextEditingController(text: 'Flash off');
  final _cancelController = TextEditingController(text: 'Cancel');
  var _aspectTolerance = 0.00;
  var _numberOfCameras = 0;
  var _selectedCamera = -1;
  var _useAutoFocus = true;
  var _autoEnableFlash = false;
  static final _possibleFormats = BarcodeFormat.values.toList()
    ..removeWhere((e) => e == BarcodeFormat.unknown);

  List<BarcodeFormat> selectedFormats = [..._possibleFormats];
  List<List<String>> _secretKeysNameData = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();
    loadSecretKeys().then((value) {
      currentTOTPs = List.filled(_secretKeysNameData.length, "");
      Future.delayed(Duration.zero, () async {
        _numberOfCameras = await BarcodeScanner.numberOfCameras;
        // generateAllTOTPs();
        if (!_secretKeysNameData.isEmpty) {
          startTimer();
          setState(() {});
        }
      });
    });
  }

  Future<void> loadSecretKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? secretKeyManager = prefs.getStringList('secretKeyManager');

    if (secretKeyManager != null) {
      setState(() {
        _secretKeysNameData =
            secretKeyManager.map((entry) => entry.split(',')).toList();
      });
    }
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timerCountdown <= 0) {
        generateAllTOTPs();
        setState(() {
          timerCountdown = getTimeUntilNextStep();
        });
      } else {
        setState(() {
          timerCountdown--;
        });
      }
    });
  }

  void stopTimer() {
    if (timer != null && timer!.isActive) {
      timer?.cancel();
      timer = null;
    }
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  void generateAllTOTPs() {
    for (int i = 0; i < _secretKeysNameData.length; i++) {
      String secret = _secretKeysNameData[i][1];

      String otp = generateTOTP(secret);
      currentTOTPs[i] = otp;
    }
  }

  bool isValidBase32(String input) {
    final RegExp base32Regex = RegExp('^[A-Z2-7]+=*\$', caseSensitive: false);
    return base32Regex.hasMatch(input);
  }

  String generateTOTP(String secret,
      {int timeStep = 30, int digits = 6, int? currentTime}) {
    currentTime ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
    currentTime += 3; //added time difference

    currentTime ~/= timeStep;

    final timeBytes = ByteData(8);
    timeBytes.setUint64(0, currentTime);

    final secretBytes = base32.decode(secret);
    final hmac = Hmac(sha1, secretBytes);
    final hmacResult = hmac.convert(timeBytes.buffer.asUint8List());

    final offset = hmacResult.bytes[hmacResult.bytes.length - 1] & 0xF;

    final truncatedHash = hmacResult.bytes.sublist(offset, offset + 4);
    final int otp =
        truncatedHash.fold<int>(0, (value, element) => (value << 8) + element) %
            (pow(10, digits) as int);

    final otpStr = otp.toString().padLeft(digits, '0');

    return otpStr;
  }

  int getTimeUntilNextStep({int timeStep = 30}) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return timeStep - ((currentTime + 3) % timeStep); //added time difference
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AllOne Authenticator'),
            SizedBox(width: 10),
            PopupMenuButton<String>(
              offset: Offset(0, 40),
              onSelected: (value) {
                if (value == 'scan') {
                } else if (value == 'enterCode') {}
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  onTap: () {
                    _scan();
                  },
                  value: 'scan',
                  child: Row(
                    children: [
                      Icon(
                        Icons.qr_code,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text('Scan'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  onTap: () {
                    _showInputDialog(context, false);
                    stopTimer();
                  },
                  value: 'enterCode',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text('Manually Enter Code'),
                    ],
                  ),
                ),
              ],
              child: Icon(Icons.add),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(66, 176, 174, 174),
        toolbarHeight: 60,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Column(
                children: _secretKeysNameData.isNotEmpty
                    ? List.generate(
                        _secretKeysNameData.length,
                        (index) => Column(
                          children: [
                            _totpCardBuilder(
                              _secretKeysNameData[index],
                              currentTOTPs[index],
                              index,
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      )
                    : [
                        Container(
                          height: MediaQuery.of(context).size.height -
                              (MediaQuery.of(context).size.height) / 3,
                          child: Center(
                            child: Text(
                              "Add Your Authenticator Codes Here !",
                              style: TextStyle(
                                color: Color.fromARGB(91, 255, 255, 255),
                                fontSize: 56,
                                fontWeight: FontWeight.w100,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _totpCardBuilder(List<String> data, String currentTOTP, int index) {
    return GestureDetector(
      onTap: () {
        _showInputDialog(context, true);
        keyController.text = data[1].toString();
        nameController.text = data[0].toString();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        FlutterClipboard.copy(currentTOTP);
        showSnackBar(context, 'Copied To Clipboard');
      },
      child: Container(
          width: MediaQuery.of(context).size.width -
              (MediaQuery.of(context).size.width) / 20,
          height: MediaQuery.of(context).size.height / 6,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: index.isEven
                  ? Colors.grey[800]
                  : Color.fromARGB(136, 255, 255, 255)),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        data[0],
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        currentTOTP,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.w300),
                      ),
                      Text(
                        timerCountdown.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }

  void _showInputDialog(BuildContext context, bool forEdit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Secret Key and Name'),
          content: Container(
            height: MediaQuery.of(context).size.height / 5,
            child: Column(
              children: [
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(labelText: 'Enter Secret Key'),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
              ],
            ),
          ),
          actions: [
            !forEdit
                ? ElevatedButton(
                    onPressed: () async {
                      String key = keyController.text.toString();
                      String name = nameController.text.toString();
                      if (key.isEmpty || name.isEmpty) {
                        showSnackBar(context, "Value cannot be empty");
                        return;
                      }
                      if (!isValidBase32(key)) {
                        showSnackBar(context, "Enter Valid key");
                        return;
                      }
                      List<String> nameKeyData = [
                        name,
                        key.replaceAll(RegExp(r'\s'), '')
                      ];

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      List<String>? secretKeyManager =
                          prefs.getStringList('secretKeyManager');
                      secretKeyManager ??= [];
                      secretKeyManager.add(nameKeyData.join(','));
                      prefs.setStringList('secretKeyManager', secretKeyManager);
                      setState(() {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (builder) => HomePage()),
                            (route) => false);
                      });
                      // Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      String key = keyController.text.toString();
                      String name = nameController.text.toString();

                      if (key.isNotEmpty && name.isNotEmpty) {
                        await deleteSecretKey(name, key);
                      }
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (builder) => HomePage()),
                          (route) => false);
                    },
                    child: Text('Delete'),
                  ),
          ],
        );
      },
    );
  }

  Future<void> deleteSecretKey(String name, String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? secretKeyManager = prefs.getStringList('secretKeyManager');

    if (secretKeyManager != null) {
      String entryToDelete = name + ',' + key;

      int indexToDelete = -1;
      for (int i = 0; i < secretKeyManager.length; i++) {
        if (entryToDelete == secretKeyManager[i]) {
          setState(() {
            indexToDelete = i;
          });
        }
      }

      if (indexToDelete != -1) {
        secretKeyManager.removeAt(indexToDelete);
        prefs.setStringList('secretKeyManager', secretKeyManager);
        setState(() {
          loadSecretKeys();
        });
      }
    }
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _scan() async {
    stopTimer();
    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': _cancelController.text,
            'flash_on': _flashOnController.text,
            'flash_off': _flashOffController.text,
          },
          restrictFormat: selectedFormats,
          useCamera: _selectedCamera,
          autoEnableFlash: _autoEnableFlash,
          android: AndroidOptions(
            aspectTolerance: _aspectTolerance,
            useAutoFocus: _useAutoFocus,
          ),
        ),
      );
      setState(() {
        scanResult = result;
        _showInputDialog(context, false);
        keyController.text = scanResult?.rawContent ?? '';
      });
    } on PlatformException catch (e) {
      setState(() {
        scanResult = ScanResult(
          rawContent: e.code == BarcodeScanner.cameraAccessDenied
              ? 'The user did not grant the camera permission!'
              : 'Unknown error: $e',
        );
      });
    }
  }
}
