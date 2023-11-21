import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:planner_app/Service/Auth_Service.dart';
import 'package:planner_app/Service/EncryptionService.dart';
import 'package:planner_app/pages/AddToDo.dart';
import 'package:uuid/uuid.dart';

class StrengthPage extends StatefulWidget {
  final Map<String, dynamic> mp;
  final List<String> categories;
  const StrengthPage({super.key, required this.mp, required this.categories});

  @override
  State<StrengthPage> createState() => _StrengthPageState();
}

class _StrengthPageState extends State<StrengthPage> {
  Map<String, dynamic> passwordsMap = {};
  List<dynamic> Passwords = [];
  List<dynamic> currentState = [];
  List<String> categories = [];
  String currentStateKey = "";
  AuthClass _authClass = AuthClass();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late final user;
  final uuid = Uuid();
  late final userid;
  late EncryptionService _encryptionService;
  @override
  void initState() {
    user = auth.currentUser;
    userid = user?.uid;
    _encryptionService = EncryptionService('${userid}');
    passwordsMap = widget.mp;
    categories = widget.categories;
    fillPasswordsList(passwordsMap);
    super.initState();
  }

  void changeState(String val) {
    this.setState(() {
      currentState = passwordsMap[val];
      currentStateKey = val;
    });
  }

  void fillPasswordsList(Map<String, dynamic> mp) {
    mp.forEach((key, value) {
      List<dynamic> temp = mp[key];
      for (int i = 0; i < temp.length; i++) {
        setState(() {
          String encpass = _encryptionService.decrypt(temp[i]['password']);
          int passPercent = calculatePasswordStrength(encpass);
          temp[i]['passpercentage'] = passPercent;
          Passwords.add(temp[i]);
        });
      }
    });
  }

  int calculatePasswordStrength(String password) {
    int lengthScore = password.length >= 8 ? 10 : 0;
    int lowercaseScore = password.contains(RegExp(r'[a-z]')) ? 5 : 0;
    int uppercaseScore = password.contains(RegExp(r'[A-Z]')) ? 5 : 0;
    int digitScore = password.contains(RegExp(r'[0-9]')) ? 5 : 0;
    int symbolScore =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) ? 10 : 0;

    Set<String> uniqueChars = password.split('').toSet();
    int uniqueCharsScore = uniqueChars.length >= 5 ? 5 : 0;

    int numRulesEnforced = [
      lengthScore,
      lowercaseScore,
      uppercaseScore,
      digitScore,
      symbolScore,
      uniqueCharsScore
    ].where((score) => score > 0).length;

    int weightedScore = numRulesEnforced * 10;
    int passwordStrength = lengthScore +
        lowercaseScore +
        uppercaseScore +
        digitScore +
        symbolScore +
        uniqueCharsScore +
        weightedScore;

    return passwordStrength;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            toolbarHeight: 50,
            title: Row(
              children: [
                Text(
                  "Strength Checker ",
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
          backgroundColor: Colors.black,
          body: RefreshIndicator(
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
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: CustomScrollView(
                                slivers: <Widget>[
                                  SliverPadding(
                                    padding: EdgeInsets.only(top: 20),
                                  ),
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (BuildContext context, int index) {
                                        Color itemColor = index.isOdd
                                            ? Color.fromARGB(186, 255, 255, 255)
                                            : Color.fromARGB(141, 51, 51, 52);
                                        double itemHeight =
                                            index == 4 ? 60.0 : 60.0;
                                        double gapHeight = 20.0;
                                        double blurHeight = 40.0;

                                        bool isTapped = Passwords[index]
                                                ['isTapped'] ??
                                            false;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: gapHeight),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (builder) =>
                                                      AddTodoPage(
                                                          propData:
                                                              Passwords[index],
                                                          parentKey:
                                                              currentStateKey,
                                                          categorieslist:
                                                              categories),
                                                ),
                                                (route) => false,
                                              );

                                              setState(() {
                                                Passwords[index]['isTapped'] =
                                                    !isTapped;
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: itemColor,
                                                border: Border.all(
                                                  color: isTapped
                                                      ? Colors.green
                                                      : Colors.transparent,
                                                  width: 2.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Container(
                                                  height: itemHeight,
                                                  alignment: Alignment.center,
                                                  child: Stack(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          SizedBox(width: 25),
                                                          Container(
                                                            width: 50,
                                                            child: SvgPicture
                                                                .asset(
                                                              Passwords[index]
                                                                  ['iconpath'],
                                                              width: 24,
                                                              height: 24,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 150,
                                                            child: Text(
                                                              '${Passwords[index]['name']}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                color: index
                                                                        .isEven
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                SizedBox(
                                                                    width: 8),
                                                                CircularPercentIndicator(
                                                                  key:
                                                                      UniqueKey(), // Add this line
                                                                  radius: 20,
                                                                  animationDuration:
                                                                      1000,
                                                                  animation:
                                                                      true,
                                                                  lineWidth: 6,
                                                                  percent: Passwords[
                                                                              index]
                                                                          [
                                                                          'passpercentage'] /
                                                                      100,
                                                                  progressColor: Passwords[index]
                                                                              [
                                                                              'passpercentage'] <
                                                                          50
                                                                      ? Color.fromARGB(
                                                                          255,
                                                                          244,
                                                                          67,
                                                                          54)
                                                                      : Colors
                                                                          .green,
                                                                  backgroundColor: Passwords[index]
                                                                              [
                                                                              'passpercentage'] <
                                                                          50
                                                                      ? Color.fromARGB(
                                                                          76,
                                                                          244,
                                                                          67,
                                                                          54)
                                                                      : const Color
                                                                          .fromARGB(
                                                                          55,
                                                                          76,
                                                                          175,
                                                                          79),
                                                                  circularStrokeCap:
                                                                      CircularStrokeCap
                                                                          .round,
                                                                  center: Text(
                                                                    Passwords[index]
                                                                            [
                                                                            'passpercentage']
                                                                        .toString(),
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Positioned(
                                                        right: 15,
                                                        bottom: -1,
                                                        child: Image.asset(
                                                          'assets/opencard.png',
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: Passwords.length,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onRefresh: _refreshData)),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      passwordsMap = {};
      categories = [];
      Passwords = [];
      passwordsMap = widget.mp;
      categories = widget.categories;
      fillPasswordsList(passwordsMap);
      setState(() {});
    });
  }
}
