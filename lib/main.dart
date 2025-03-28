import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _DateState();
}

const Color primaryColor = const Color(0xff5a21fe);
const Color bgColor = const Color.fromARGB(255, 97, 44, 255);

class _DateState extends State<App> {
  String _dateStr = "0";
  String day = '00';
  String month = '00';
  String year = '00';
  String hour = '00';
  String second = '00';
  String mini = '00';
  void updateDates(String str) {
    DateTime date = DateTime.now();
    setState(() {
      _dateStr = date.toString();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("初始化");
    Timer.periodic(const Duration(milliseconds: 1), (timer) {
      setState(() {
        _dateStr = DateTime.now().toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.tightFor(width: 200.0, height: 200.0),
      color: Color.fromARGB(255, 50, 73, 99),

      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            _dateStr,
            style: TextStyle(
              color: Color.fromARGB(255, 255, 197, 8),
              fontWeight: FontWeight.bold,
              fontSize: 50.0,
            ),
          ),
        ),
      ),
    );
  }
}
