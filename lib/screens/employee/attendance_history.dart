// 員工打卡歷史頁attendance_history.dart
import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';
import '../../models/attendance_record.dart';

class AttendanceHistory extends StatefulWidget {
  final String? employeeId; // 如果傳入員工編號，只看該員工紀錄

  const AttendanceHistory({Key? key, this.employeeId}) : super(key: key);

  @override
  _AttendanceHistoryState createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  List<AttendanceRecord> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() async {
    List<AttendanceRecord> allRecords = await SqliteService.getAllRecords();
    if (widget.employeeId != null) {
      records = allRecords
          .where((r) => r.employeeId == widget.employeeId)
          .toList();
    } else {
      records = allRecords;
    }
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 最新在前
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('打卡紀錄')),
      body: records.isEmpty
          ? Center(child: Text('沒有打卡紀錄'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (_, index) {
                final rec = records[index];
                return ListTile(
                  title: Text('${rec.employeeId} - ${rec.type}'),
                  subtitle: Text('${rec.timestamp}'),
                );
              },
            ),
    );
  }
}
