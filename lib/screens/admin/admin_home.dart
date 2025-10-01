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
            icon: Icon(Icons.insert_chart), // 報表按鈕
            tooltip: '月報表',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MonthlyReport()),
              );
            },
          ),

          // 員工管理按鈕
          IconButton(
            icon: Icon(Icons.group),
            tooltip: '員工管理',
            onPressed: _openEmployeePage, // 新增按鈕
          ),

          // 清理半年以前打卡紀錄按鈕
          IconButton(
            icon: Icon(Icons.cleaning_services), // 清理圖示
            tooltip: '清理半年以前打卡紀錄',
            onPressed: () async {
              // 彈出確認對話框
              bool? confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('確認清理'),
                  content: Text('確定要刪除半年以前的打卡紀錄嗎？此操作無法復原。'),
                  actions: [
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      child: Text('確認'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                int deletedCount = await SqliteService.deleteOldRecords();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已刪除 $deletedCount 筆半年以前的打卡紀錄')),
                );
                _loadRecords(); // 刷新列表
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (_, index) {
          final rec = records[index];
          return ListTile(
            //顯示紀錄
            title: Row(
              children: [
                Text(
                  rec.name,
                  style: TextStyle(
                    color: rec.isManual ? Colors.red : Colors.black, // 補卡紅字
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  rec.type,
                  style: TextStyle(
                    color: rec.isManual ? Colors.red : Colors.black, // 補卡紅字
                  ),
                ),
              ],
            ),
            // title: Text('${rec.name} ${rec.type}'),
            subtitle: Text(
              '${rec.timestamp}',
              style: TextStyle(
                color: rec.isManual ? Colors.red : Colors.black, // 補卡紅字
              ),
            ),

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
