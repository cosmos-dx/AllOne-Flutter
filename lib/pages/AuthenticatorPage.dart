import 'dart:async';
import 'dart:math';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  List<Timer> timers = [];
  ScanResult? scanResult;
  Timer? _timer;
  int _countdown = 0;
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
  List<List<String>> _secretKeysNameData = [
    ["Instagram", "JBSWY3DPEHPK3PXP"],
    ["Facebook", "JBSXY3DPGHPK3PXP"],
    ["Jacob", "JBSWY3DPEHPK3PPP"],
    ["America", "JBSWY3DPELPKPPXP"],
    ["Reddit", "JBSWY3DPEHPK3PXP"],
    ["Google", "JBSWP3DPWHPK3PXP"],
    ["Microsoft", "JBSWY3DPEHOK3PXP"],
  ];

  @override
  void initState() {
    super.initState();
    currentTOTPs = List.filled(_secretKeysNameData.length, "");
    startTimers();
    Future.delayed(Duration.zero, () async {
      _numberOfCameras = await BarcodeScanner.numberOfCameras;
      setState(() {});
    });
  }

  void startTimers() {
    for (int i = 0; i < _secretKeysNameData.length; i++) {
      startTimerForIndex(i);
    }
  }

  void startTimerForIndex(int index) {
    Timer timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTOTPs[index] = generateTOTP(
          _secretKeysNameData[index][1],
          currentTime: (DateTime.now().millisecondsSinceEpoch ~/ 1000),
        );
        _countdown = getTimeUntilNextStep();
      });
    });

    timers.add(timer);
  }

  void stopTimers() {
    for (var timer in timers) {
      timer.cancel();
    }
    timers.clear();
  }

  @override
  void dispose() {
    stopTimers();
    super.dispose();
  }

  String generateTOTP(String secret,
      {int timeStep = 30, int digits = 6, int? currentTime}) {
    currentTime ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
    return timeStep - (currentTime % timeStep);
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
                    _showInputDialog(context);
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
            InkWell(
              onTap: () {},
              child: Icon(Icons.edit),
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
                children: List.generate(
                  _secretKeysNameData.length,
                  (index) => Column(
                    children: [
                      _totpCardBuilder(
                          _secretKeysNameData[index], currentTOTPs[index]),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _totpCardBuilder(List<String> data, String currentTOTP) {
    return Container(
      width: MediaQuery.of(context).size.width -
          (MediaQuery.of(context).size.width) / 20,
      height: MediaQuery.of(context).size.height / 6,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.grey[800]),
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
                // CircularPercentIndicator(
                //   radius: 20,
                //   animationDuration: getTimeUntilNextStep(),
                //   animation: true,
                //   progressColor: const Color.fromARGB(255, 6, 255, 15),
                //   backgroundColor: Color.fromARGB(52, 118, 255, 64),
                //   lineWidth: 6,
                //   circularStrokeCap: CircularStrokeCap.round,
                //   percent: _percentTimer,
                // )
                Text(
                  _countdown.toString(),
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
    );
  }

  void _showInputDialog(BuildContext context) {
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
                  decoration: InputDecoration(labelText: 'Enter Sceret Key'),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                String key = keyController.text;
                String name = nameController.text;
                if (key.isEmpty || name.isEmpty) {
                  showSnackBar(context, "Value Can not be empty");
                  return;
                }
                setState(() {
                  stopTimers();
                  _secretKeysNameData.add([name, key]);
                  currentTOTPs.add("");
                  startTimers();
                });
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showSnackBar(BuildContext context, String texti) {
    final snackBar = SnackBar(content: Text(texti));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _scan() async {
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
        _showInputDialog(context);
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
