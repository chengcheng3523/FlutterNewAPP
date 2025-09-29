// 員工打卡頁employee_home.dart
import 'package:flutter/material.dart';
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

  void _checkInOut(String type) async {
    String empId = _idController.text.trim();
    if (empId.isEmpty) return;

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
            '$type 成功！${DateFormat('yyyy-MM-dd HH:mm:ss').format(record.timestamp)}',
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
