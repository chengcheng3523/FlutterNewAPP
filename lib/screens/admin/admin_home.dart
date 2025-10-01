// 管理員主頁admin_home.dart
import 'package:flutter/material.dart';
import 'edit_record.dart';
import 'monthly_report.dart';
import 'admin_employee_page.dart'; // 新增：員工管理頁
import '../../services/sqlite_service.dart';
import '../../models/attendance_record.dart';

class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

// 管理員主頁，顯示所有打卡紀錄，並可編輯、刪除紀錄
class _AdminHomeState extends State<AdminHome> {
  List<AttendanceRecord> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() async {
    records = await SqliteService.getAllRecords();
    setState(() {});
  }

  void _editRecord(AttendanceRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditRecord(record: record)),
    );
    _loadRecords();
  }

  void _deleteRecord(int id) async {
    await SqliteService.deleteRecord(id);
    _loadRecords();
  }

  void _openEmployeePage() async {
    // 進入員工管理頁，返回後重新載入資料
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminEmployeePage()),
    );
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('管理員介面'),
        actions: [
          IconButton(
            icon: Icon(Icons.insert_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MonthlyReport()),
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.group),
            tooltip: '員工管理',
            onPressed: _openEmployeePage, // 新增按鈕
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (_, index) {
          final rec = records[index];
          return ListTile(
            //顯示紀錄
            title: Text('${rec.name} ${rec.type}'),
            subtitle: Text('${rec.timestamp}'),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editRecord(rec),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteRecord(rec.id!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
