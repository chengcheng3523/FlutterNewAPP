// 月報表統計頁monthly_report.dart
import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';
import '../../models/attendance_record.dart';
import 'package:intl/intl.dart';

class MonthlyReport extends StatefulWidget {
  const MonthlyReport({Key? key}) : super(key: key);

  @override
  _MonthlyReportState createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<MonthlyReport> {
  Map<String, Map<String, List<AttendanceRecord>>> groupedRecords = {};
  Map<String, Map<String, Duration>> dailyDurations = {};
  Map<String, Duration> monthlyTotals = {};

  @override
  void initState() {
    super.initState();
    _calculateHours();
  }

  void _calculateHours() async {
    List<AttendanceRecord> records = await SqliteService.getAllRecords();
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 依年月、員工分組
    Map<String, Map<String, List<AttendanceRecord>>> tempGrouped = {};
    Map<String, Map<String, Duration>> tempDailyDur = {};
    Map<String, Duration> tempMonthlyTotal = {};

    for (var r in records) {
      String yearMonth = DateFormat('yyyy-MM').format(r.timestamp);
      String empName = r.name ?? r.employeeId;

      tempGrouped.putIfAbsent(yearMonth, () => {});
      tempGrouped[yearMonth]!.putIfAbsent(empName, () => []);
      tempGrouped[yearMonth]![empName]!.add(r);
    }

    // 計算每日上班時數
    tempGrouped.forEach((yearMonth, empMap) {
      empMap.forEach((empName, recs) {
        Map<String, Duration> dayDur = {};
        Duration totalDur = Duration.zero;

        // 依日期分組
        Map<String, List<AttendanceRecord>> dailyRecords = {};
        for (var r in recs) {
          String day = DateFormat('yyyy-MM-dd').format(r.timestamp);
          dailyRecords.putIfAbsent(day, () => []);
          dailyRecords[day]!.add(r);
        }

        // 計算每日工時
        dailyRecords.forEach((day, recs) {
          recs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          Duration dayDuration = Duration.zero;
          for (int i = 0; i < recs.length - 1; i += 2) {
            if (recs[i].type == '上班' && recs[i + 1].type == '下班') {
              dayDuration += recs[i + 1].timestamp.difference(recs[i].timestamp);
            }
          }
          dayDur[day] = dayDuration;
          totalDur += dayDuration;
        });

        tempDailyDur.putIfAbsent(yearMonth, () => {});
        tempDailyDur[yearMonth]![empName] = dayDur.values.fold(Duration.zero, (a, b) => a + b);

        tempMonthlyTotal.putIfAbsent(yearMonth + '_' + empName, () => totalDur);
      });
    });

    setState(() {
      groupedRecords = tempGrouped;
      dailyDurations = tempDailyDur;
      monthlyTotals = tempMonthlyTotal;
    });
  }

  String formatDuration(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes % 60;
    int seconds = d.inSeconds % 60;
    return '$hours 小時 $minutes 分 $seconds 秒';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('月統計報表')),
      body: ListView(
        children: groupedRecords.entries.map((ymEntry) {
          String yearMonth = ymEntry.key;
          return ExpansionTile(
            title: Text(yearMonth),
            children: ymEntry.value.entries.map((empEntry) {
              String empName = empEntry.key;
              List<AttendanceRecord> recs = empEntry.value;
              String monthKey = '$yearMonth\_$empName';
              Duration total = monthlyTotals[monthKey] ?? Duration.zero;

              // 依日期分組
              Map<String, List<AttendanceRecord>> dailyRecords = {};
              for (var r in recs) {
                String day = DateFormat('yyyy-MM-dd').format(r.timestamp);
                dailyRecords.putIfAbsent(day, () => []);
                dailyRecords[day]!.add(r);
              }

              return ExpansionTile(
                title: Text('$empName 總工時：${formatDuration(total)}'),
                children: dailyRecords.entries.map((dayEntry) {
                  String day = dayEntry.key;
                  List<AttendanceRecord> dayRecs = dayEntry.value;
                  Duration dayDuration = Duration.zero;
                  for (int i = 0; i < dayRecs.length - 1; i += 2) {
                    if (dayRecs[i].type == '上班' && dayRecs[i + 1].type == '下班') {
                      dayDuration += dayRecs[i + 1].timestamp.difference(dayRecs[i].timestamp);
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$day 上班時數：${formatDuration(dayDuration)}'),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dayRecs.map((r) {
                            return Text(
                              '${DateFormat('HH:mm:ss').format(r.timestamp)} ${r.type}',
                              style: TextStyle(
                                color: r.isManual ? Colors.red : Colors.black,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
