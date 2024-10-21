import 'dart:async';

import 'package:flutter/material.dart';

import 'package:watch_connectivity/watch_connectivity.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _watch = WatchConnectivity();

  ChartSeriesController? _chartSeriesController;

  var _supported = false;
  var _paired = false;
  var _reachable = false;
  var _context = <String, dynamic>{};
  var _receivedContexts = <Map<String, dynamic>>[];
  final _log = <String>[];

  var hearRateData = <double>[];
  var hearRateFullData = <double>[];

  Timer? timer;

  @override
  void initState() {
    super.initState();

    _watch.messageStream.listen((e) {
      setState(() => _log.add('Received message: $e'));
      // print("Whole: $e");
      // print("Bool: ${e.containsKey("HeartRate")}");
      // print("Type: ${e["HeartRate"].runtimeType}");
      // print("Value: ${e["HeartRate"]}");
      // print("Len Data: ${hearRateData.length}");
      // print("Len FullData: ${hearRateFullData.length}");
      if (e["HeartRate"] != 0.0) {
        hearRateFullData.add(e["HeartRate"]);
        hearRateData.add(e["HeartRate"]);
        if (hearRateData.length == 20) {
          hearRateData.removeAt(0);
          _chartSeriesController?.updateDataSource(
              addedDataIndex: hearRateData.length - 1, removedDataIndex: 0);
        }
      }
    });

    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void initPlatformState() async {
    _supported = await _watch.isSupported;
    _paired = await _watch.isPaired;
    _reachable = await _watch.isReachable;
    _context = await _watch.applicationContext;
    _receivedContexts = await _watch.receivedApplicationContexts;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SfCartesianChart(
                    series: <LineSeries<double, int>>[
                      LineSeries<double, int>(
                        onRendererCreated: (ChartSeriesController controller) {
                          _chartSeriesController = controller;
                        },
                        dataSource: hearRateData,
                        xValueMapper: (_, index) => index,
                        yValueMapper: (heartRate, _) => heartRate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Send'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: startGame,
                        child: const Text('Start Game'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: endGame,
                        child: const Text('End Game'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Text('Log'),
                  ..._log.reversed.map(Text.new),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void startGame() {
    final message = {'Command': 'START_GAME'};
    _watch.sendMessage(message);
    setState(() => _log.add('Sent message: $message'));
  }

  void endGame() {
    final message = {'Command': 'END_GAME'};
    _watch.sendMessage(message);
    setState(() => _log.add('Sent message: $message'));
  }
}
