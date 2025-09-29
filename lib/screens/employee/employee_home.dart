// 員工打卡頁employee_home.dart
// 員工進行打卡的主畫面
import 'package:flutter/material.dart';
import 'dart:async'; // 新增：Timer 用
import 'attendance_history.dart';
import '../admin/admin_login.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record.dart';
import '../../services/sqlite_service.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({Key? key}) : super(key: key);

  @override
  _EmployeeHomeState createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  final TextEditingController _idController = TextEditingController();

  DateTime now = DateTime.now(); // 當前時間
  Timer? _timer; // 定時器

  @override
  void initState() {
    super.initState();
    // 每秒更新一次時間
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idController.dispose();
    super.dispose();
  }

  // 打卡（上班/下班）
  void _checkInOut(String type) async {
    String empId = _idController.text.trim();
    if (empId.isEmpty) return;

    // 取得員工姓名
    String empName = '';
    final employees = await SqliteService.getAllEmployees();
    final emp = employees.firstWhere(
      (e) => e['id'].toString() == empId,
      orElse: () => {},
    );
    empName = emp['name'] ?? '';
    if (empName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('找不到員工編號 $empId')));
      }
      return;
    }

    // 建立打卡紀錄
    AttendanceRecord record = AttendanceRecord(
      employeeId: empId,
      timestamp: DateTime.now(),
      type: type,
    );

    await SqliteService.insertRecord(record);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$type 成功！編號：$empId 姓名：$empName\n時間：${DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp)}',
          ),
        ),
      );
    }

    _idController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('員工打卡'),
        leading: IconButton(
          icon: Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AttendanceHistory()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminLogin()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 當前時鐘顯示
            Text(
              '現在時間：${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '員工編號',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _checkInOut('上班'),
                  child: Text('上班'),
                ),
                ElevatedButton(
                  onPressed: () => _checkInOut('下班'),
                  child: Text('下班'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
