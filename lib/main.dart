import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zuzu/ad_mob_service.dart';
import 'constans.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'restartWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  var devices = ["983096CFD913AFE1D11A7C67AFCBF9E7"];
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  RequestConfiguration requestConfiguration = RequestConfiguration(
    testDeviceIds: devices,
  );
  MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  runApp(RestartWidget(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelime Oyunu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String squareText = 'X';
  Map<String, GameCell?> squares = {};
  List<String> columnIDs = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  int rowNumber = 10;
  int columnNumber = 8;
  static int newCharPeriodSecond = 5;
  int wrongTryNumber = 0;
  List<BoxShape> shapes = [GameCellShape.firstShape, GameCellShape.secondShape];
  List<Color> colors = [
    GameColors.firstColor,
    const Color.fromARGB(255, 244, 242, 97),
    GameColors.thirdColor,
    const Color.fromARGB(255, 233, 106, 222),
    GameColors.fifthColor
  ];
  List<String> selectedCells = [];
  List<String> foundWords = [];
  TextEditingController wordController = TextEditingController();
  TextEditingController pointController = TextEditingController();
  int totalPoint = 0;
  late SharedPreferences prefs;
  final String _vowels = 'AEIİÖOUÜ';
  final String _consonant = 'BCÇDFGĞHJKLMNPRSŞTVYZ';
  final Random _rnd = Random();
  bool isVowel = true;
  bool pause = false;
  bool isGameOver = false;
  bool isCanPause = false;
  Widget pointTable = const SizedBox();
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _createBannerAd();
    _createInterstitialAd();
    pointController.text = totalPoint.toString();
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!pause) {
        first(rowNumber);
        Timer.periodic(const Duration(milliseconds: 300), (timer) {
          if (timer.tick == 10) {
            timer.cancel();
          }
          shiftAll();
        });
        if (timer.tick == 3) {
          isCanPause = true;
          timer.cancel();
        }
      }
    });
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!pause) {
        shiftAll();
      }
    });

    Timer(const Duration(milliseconds: 9500), () {
      Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        if (!pause && timer.tick % newCharPeriodSecond == 0) {
          singlechar(
            10,
            getRandomnum(),
            GameCell(
              cellText: _getRandomString(1),
              shape: shapes[_rnd.nextInt(2)],
              color: colors[_rnd.nextInt(5)],
            ),
          );
        }
      });
    });
  }

  _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  _createBannerAd() {
    if (Platform.isAndroid) {
      _bannerAd = BannerAd(
          size: AdSize.banner,
          adUnitId: AdMobService.bannerAdUnitId!,
          listener: AdMobService.bannerAdListener,
          request: const AdRequest())
        ..load();
    }
  }

  _createInterstitialAd() {
    if (Platform.isAndroid) {
      InterstitialAd.load(
          adUnitId: AdMobService.interstitialAdUnitId!,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
              onAdLoaded: (ad) => _interstitialAd = ad,
              onAdFailedToLoad: (LoadAdError error) => _interstitialAd = null));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            if (details.velocity.pixelsPerSecond.dx > 0) {
              _onConfirmButtonPressed();
            } else {
              _onCancelButtonPressed();
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      if (!pause && isCanPause)
                        IconButton(
                            onPressed: _onPauseButtonPressed,
                            icon:
                                Icon(pause ? Icons.arrow_right : Icons.pause)),
                      Container(
                        width: double.infinity,
                        height: 120,
                        margin: const EdgeInsets.only(top: 20, bottom: 10),
                        child: Center(
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.orange, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                pointController.text,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  getTable(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          iconSize: 50,
                          icon: const Icon(Icons.cancel),
                          onPressed: _onCancelButtonPressed),
                      Text(
                        wordController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 8.0,
                        ),
                      ),
                      IconButton(
                        iconSize: 50,
                        icon: const Icon(Icons.done),
                        onPressed: _onConfirmButtonPressed,
                      ),
                    ],
                  ),
                ],
              ),
              if (pause) _getMenu(),
            ],
          )),
      bottomNavigationBar: (_bannerAd != null && pause)
          ? Container(
              color: Colors.amberAccent,
              height: 50,
              width: 100,
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Widget _getMenu() {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.only(right: 30, left: 30, top: 30, bottom: 50),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: GameColors.fifthColor, spreadRadius: 3),
          ],
        ),
        width: 300,
        height: 400,
        child: Column(
          children: [
            if (!isGameOver) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    pause = !pause;
                  });
                },
                child: const Text(
                  "Devam et",
                  style: TextStyle(color: GameColors.fifthColor, fontSize: 25),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
            TextButton(
              onPressed: () {
                _showInterstitialAd();
                RestartWidget.restartApp(context);
              },
              child: const Text(
                "Yeniden başlat",
                style: TextStyle(color: GameColors.fifthColor, fontSize: 25),
              ),
            ),
            const Spacer(),
            pointTable,
            // Container(
            //   color: Colors.amberAccent,
            //   height: 50,
            //   width: 100,
            //   child: AdWidget(ad: _bannerAd!),
            // ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  _getScores() async {
    prefs = await SharedPreferences.getInstance();
    List<String> newScores = [];
    List<int> scoresInt = [];
    var scores = prefs.getStringList('scores') ?? [];

    if (scores.isNotEmpty) {
      for (var element in scores) {
        scoresInt.add(int.parse(element));
      }
    }
    scoresInt.add(totalPoint);
    scoresInt.sort();
    for (var element in scoresInt.reversed) {
      if (newScores.length == 3) {
        break;
      }
      newScores.add(element.toString());
    }

    prefs.setStringList('scores', newScores);
    setState(() {
      pointTable = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: GameColors.secondColor, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            const Text("En yüksek 3 skor:"),
            for (int i = 0; i < newScores.length; i++) ...[
              Text("${newScores[i]}"),
            ],
            const SizedBox(
              height: 20,
            ),
            Text("Senin skorun: $totalPoint"),
          ],
        ),
      );
    });
  }

  _onPauseButtonPressed() {
    _createBannerAd();
    setState(() {
      pause = !pause;
      _getScores();
    });
  }

  Widget getTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[700]),
      child: Center(
        child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8, childAspectRatio: 1),
            itemCount: 80,
            itemBuilder: (context, index) {
              var row = index ~/ columnNumber;
              var column = index % columnNumber;
              var boardRank = '${(9 - row) + 1}';
              var boardFile = columnIDs[column];
              GameCell? cell = squares['$boardFile$boardRank'];

              return GestureDetector(
                onTap: () {
                  if (selectedCells.contains('$boardFile$boardRank')) {
                    selectedCells.remove('$boardFile$boardRank');
                  } else {
                    if (selectedCells.length > 9) {
                      return;
                    }
                    selectedCells.add('$boardFile$boardRank');
                  }
                  squares['$boardFile$boardRank'] = GameCell(
                    cellText: cell!.cellText,
                    shape: cell.shape,
                    color: cell.color,
                    isSelected: !cell.isSelected,
                  );
                  _onCellTop();
                },
                child: Center(
                  child: cell,
                ),
              );
            }),
      ),
    );
  }

  int getRandomnum() {
    return Random().nextInt(8);
  }

  _onCellTop() {
    setState(() {
      wordController.text = "";
      for (var element in selectedCells) {
        var cell = squares[element];
        if (cell == null) {
          continue;
        }
        wordController.text += cell.cellText;
      }
    });
  }

  void shiftAll() async {
    for (int col = 0; col < 8; col++) {
      for (int row = 1; row < 11; row++) {
        String currentId = '${files[col]}$row';
        String aboveId = '${files[col]}${row + 1}';
        if (squares[currentId] == null && squares[aboveId] != null) {
          setState(() {
            var last = squares[aboveId];
            squares[currentId] = squares[aboveId];
            if (squares[aboveId] == last) squares[aboveId] = null;
          });
        }
      }
    }
  }

  void singlechar(int rowLength, int selectedColumn, GameCell char) {
    var aboveCell = "";
    var chr = files[selectedColumn];
    aboveCell = '$chr$rowLength';
    setPiece(context, aboveCell, char);
  }

  void first(int row) {
    var aboveCell = "";
    var currentCell = '';
    for (int i = 0; i < 8; i++) {
      currentCell = '${files[i]}$row';
      int x = row - 1;
      x = row + 1;
      aboveCell = '${files[i]}$x';
      GameCell? chr;
      if (row == 10) {
        chr = GameCell(
          cellText: _getRandomString(1),
          shape: shapes[_rnd.nextInt(2)],
          color: colors[_rnd.nextInt(5)],
        );
      } else {
        chr = squares[aboveCell];
      }

      setPiece(context, currentCell, chr);
    }
  }

  void clear(String squareName) {
    setState(() {
      squares[squareName] = null;
    });
  }

  void clearrow(int row) {
    for (int i = 0; i < 8; i++) {
      var id = '';
      var chr = files[i];
      id = '$chr$row';
      clear(id);
    }
  }

  void setPiece(BuildContext context, String squareName, GameCell? abc) {
    if (squares[squareName] != null) {
      setState(() {
        pointController.text = "GAME OVER";
        isGameOver = true;
        _onPauseButtonPressed();
      });
    }
    setState(() {
      squares[squareName] = abc;
    });
  }

  _onCancelButtonPressed() {
    setState(() {
      _cleareSelectedCell();
      wordController.text = "";
    });
  }

  String _getRandomString(int length) {
    String chars = (isVowel) ? _vowels : _consonant;
    isVowel = !isVowel;
    var char = chars[_rnd.nextInt(chars.length)];
    return char;
  }

  _cleareSelectedCell() {
    for (var element in selectedCells) {
      if (squares[element] == null) {
        continue;
      }
      squares[element] = GameCell(
          cellText: squares[element]!.cellText,
          color: squares[element]!.color,
          shape: squares[element]!.shape);
    }
    setState(() {
      selectedCells.clear();
    });
  }

  _onConfirmButtonPressed() async {
    if (selectedCells.length > 10 || selectedCells.length < 3) {
      return;
    }

    if (squares[selectedCells[0]]?.cellText.toLowerCase() == "ğ") {
      _wrongWord();
      return;
    }

    String key =
        "assets/${squares[selectedCells[0]]?.cellText.toLowerCase()}${selectedCells.length}.ini";
    const splitter = LineSplitter();
    final words = splitter.convert(await loadAsset(key));
    int point = 0;

    if (foundWords.contains(wordController.text)) {
      Fluttertoast.showToast(
          msg: "Bu kelime daha önce girilmiş.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue[250],
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    if (words.contains(wordController.text)) {
      for (int i = 0; i < selectedCells.length; i++) {
        point += points[squares[selectedCells[i]]?.cellText] ?? 0;
        clear(selectedCells[i]);
      }
      if (newCharPeriodSecond > 1 &&
          totalPoint < 4 &&
          (totalPoint + point) ~/ 100 > totalPoint ~/ 100) {
        setState(() {
          newCharPeriodSecond = newCharPeriodSecond - 1;
        });
      }
      totalPoint += point;
      foundWords.add(wordController.text);
    } else {
      _wrongWord();
    }
    pointController.text = totalPoint.toString();
    _cleareSelectedCell();
    wordController.text = "";
  }

  _wrongWord() {
    wrongTryNumber += 1;
    if (wrongTryNumber == 3) {
      first(10);
      totalPoint = 0;
      wrongTryNumber = 0;
      Fluttertoast.showToast(
          msg: "3 Yanlış hakkı dolu!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
        msg: "Son ${3 - wrongTryNumber} yanlış hakkı!",
      );
    }
  }

  Future<String> loadAsset(String fileName) async {
    return await rootBundle.loadString(fileName);
  }
}
