import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '时间记录',
      theme: ThemeData(fontFamily: 'PingFang SC', brightness: Brightness.dark),
      home: TimeRecordPage(),
    );
  }
}

class TimeRecordPage extends StatefulWidget {
  @override
  _TimeRecordPageState createState() => _TimeRecordPageState();
}

class _TimeRecordPageState extends State<TimeRecordPage> {
  // 时间相关变量
  DateTime _now = DateTime.now();
  Timer? _timer;
  double _secondPercentage = 0;
  bool _colonVisible = true;

  // 计时器相关变量
  int _timerStartTime = 0;
  bool _timerRunning = false;
  Timer? _timerInterval;
  String _timerText = '00:00.00';
  bool _isWarning = false;

  // 时间记录相关变量
  List<Map<String, dynamic>> _timeRecords = [];

  // 星期和月份数组
  final List<String> _weekdays = [
    '星期日',
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
  ];
  final List<String> _months = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerInterval?.cancel();
    super.dispose();
  }

  // 加载已保存的记录
  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsString = prefs.getString('timeRecords');
    if (recordsString != null) {
      setState(() {
        _timeRecords = List<Map<String, dynamic>>.from(
          json
              .decode(recordsString)
              .map((item) => Map<String, dynamic>.from(item)),
        );
      });
    }
  }

  // 保存记录到本地存储
  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeRecords', json.encode(_timeRecords));
  }

  // 开始时间更新定时器
  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        _now = DateTime.now();
        _colonVisible = _now.second % 2 == 0;
        _secondPercentage =
            ((_now.second * 1000 + _now.millisecond) / 60000) * 100;
      });
    });
  }

  // 启动计时器
  void _startCountUpTimer() {
    _resetCountUpTimer();
    setState(() {
      _timerStartTime = DateTime.now().millisecondsSinceEpoch;
      _timerRunning = true;
    });

    _timerInterval?.cancel();
    _timerInterval = Timer.periodic(Duration(milliseconds: 10), (timer) {
      _updateCountUpTimer();
    });
  }

  // 更新计时器显示
  void _updateCountUpTimer() {
    if (!_timerRunning) return;

    int elapsedTime = DateTime.now().millisecondsSinceEpoch - _timerStartTime;

    int minutes = (elapsedTime ~/ 60000);
    int seconds = ((elapsedTime % 60000) ~/ 1000);
    int milliseconds = ((elapsedTime % 1000) ~/ 10);

    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = seconds.toString().padLeft(2, '0');
    String formattedMs = milliseconds.toString().padLeft(2, '0');

    setState(() {
      _timerText = '$formattedMinutes:$formattedSeconds.$formattedMs';
      // 3分钟 = 180000毫秒，这里设为18000毫秒以便测试（18秒）
      _isWarning = elapsedTime >= 120000;
    });
  }

  // 重置计时器
  void _resetCountUpTimer() {
    setState(() {
      _timerRunning = false;
      _timerStartTime = 0;
      _timerText = '00:00.00';
      _isWarning = false;
    });
  }

  // 记录当前时间
  void _recordTime() {
    final now = DateTime.now();
    final hours = now.hour.toString().padLeft(2, '0');
    final minutes = now.minute.toString().padLeft(2, '0');
    final seconds = now.second.toString().padLeft(2, '0');

    final record = {
      'time': '$hours:$minutes:$seconds',
      'timestamp': now.millisecondsSinceEpoch,
    };

    setState(() {
      _timeRecords.insert(0, record);
    });

    _saveRecords();
    _startCountUpTimer();
  }

  // 清除所有记录
  void _clearAllRecords() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('确认清除'),
            content: Text('确定要清除所有记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _timeRecords.clear();
                  });
                  _saveRecords();
                  _resetCountUpTimer();
                  Navigator.pop(context);
                },
                child: Text('确认'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedHour = _now.hour.toString().padLeft(2, '0');
    final String formattedMinute = _now.minute.toString().padLeft(2, '0');
    final String weekday = _weekdays[_now.weekday % 7];
    final String month = _months[_now.month - 1];
    final String day = _now.day.toString();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                _isWarning
                    ? [Color(0xFFE22D2D), Color(0xFFE04A00)]
                    : [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 左侧区域
              Expanded(
                flex: 4,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 时钟容器
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 30.0,
                          horizontal: 30.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  _isWarning
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.2),
                              blurRadius: 15.0,
                              offset: Offset(0, 15),
                            ),
                          ],
                          border: Border.all(
                            color:
                                _isWarning
                                    ? Color(0xFFFF9696).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            // 时间显示
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: formattedHour,
                                    style: TextStyle(
                                      fontSize: 84.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 5.0,
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextSpan(
                                    text: ':',
                                    style: TextStyle(
                                      fontSize: 84.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(
                                        _colonVisible ? 1.0 : 0.5,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: formattedMinute,
                                    style: TextStyle(
                                      fontSize: 84.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 5.0,
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10.0),
                            // 日期显示
                            Text(
                              '$weekday, $month$day日',
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 20.0),
                            // 秒数进度条
                            Container(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _secondPercentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(3.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.0),
                      // 底部容器 (按钮和计时器)
                      Container(
                        height: 50,
                        child: Row(
                          children: [
                            // 记录按钮
                            Expanded(
                              flex: 10,
                              child: ElevatedButton(
                                onPressed: _recordTime,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 15.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '记录当前时间',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15.0),
                            // 计时器显示
                            Expanded(
                              flex: 6,
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15.0),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.0,
                                  ),
                                  boxShadow: [],
                                ),
                                child: Text(
                                  _timerText,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 右侧区域
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 20.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _isWarning
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.2),
                          blurRadius: 15.0,
                          offset: Offset(0, 15),
                        ),
                      ],
                      border: Border.all(
                        color:
                            _isWarning
                                ? Color(0xFFFF9696).withOpacity(0.4)
                                : Colors.white.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        // 头部
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '时间记录',
                                style: TextStyle(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: _clearAllRecords,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '清除所有',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Colors.white.withOpacity(0.2),
                          height: 1.0,
                        ),
                        // 记录列表
                        Expanded(
                          child:
                              _timeRecords.isEmpty
                                  ? Center(
                                    child: Text(
                                      '暂无记录',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  )
                                  : Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 120.0,
                                            crossAxisSpacing: 8.0,
                                            mainAxisSpacing: 8.0,
                                            childAspectRatio: 2.0,
                                          ),
                                      itemCount: _timeRecords.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          padding: EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                            color:
                                                _isWarning
                                                    ? Color(
                                                      0xFFFF9696,
                                                    ).withOpacity(0.2)
                                                    : Colors.white.withOpacity(
                                                      0.1,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _isWarning
                                                      ? Color(
                                                        0xFFFF9696,
                                                      ).withOpacity(0.3)
                                                      : Colors.white
                                                          .withOpacity(0.1),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _timeRecords[index]['time'],
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
