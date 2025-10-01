// 程式進入點 (App entry point)main.dart
import 'package:flutter/material.dart';
import 'screens/employee/employee_home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '打卡系統',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EmployeeHome(), // 程式進入後顯示的第一頁
    );
  }
}
