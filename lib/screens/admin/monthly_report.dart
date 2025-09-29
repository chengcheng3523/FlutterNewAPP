// 月報表統計頁monthly_report.dart
import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';
import '../../models/attendance_record.dart';
// import 'package:intl/intl.dart';

class MonthlyReport extends StatefulWidget {
  const MonthlyReport({Key? key}) : super(key: key);

  @override
  _MonthlyReportState createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<MonthlyReport> {
  Map<String, double> employeeHours = {};

  @override
  void initState() {
    super.initState();
    _calculateHours();
  }

  void _calculateHours() async {
    List<AttendanceRecord> records = await SqliteService.getAllRecords();
    Map<String, List<AttendanceRecord>> grouped = {};

    for (var r in records) {
      grouped.putIfAbsent(r.employeeId, () => []).add(r);
    }

    grouped.forEach((empId, recs) {
      recs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      double hours = 0;
      for (int i = 0; i < recs.length - 1; i += 2) {
        if (recs[i].type == '上班' && recs[i + 1].type == '下班') {
          hours +=
              recs[i + 1].timestamp.difference(recs[i].timestamp).inMinutes /
              60;
        }
      }
      employeeHours[empId] = hours;
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('月統計報表')),
      body: ListView(
        children: employeeHours.entries.map((e) {
          return ListTile(
            title: Text('${e.key} 總工時: ${e.value.toStringAsFixed(2)} 小時'),
          );
        }).toList(),
      ),
    );
  }
}
