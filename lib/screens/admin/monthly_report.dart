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
  Map<String, Map<String, List<AttendanceRecord>>> groupedData =
      {}; // 年月 -> 員工 -> 紀錄
  Map<String, Map<String, double>> monthlyHours = {}; // 年月 -> 員工 -> 當月總工時

  @override
  void initState() {
    super.initState();
    _calculateHours();
  }

  Future<void> _calculateHours() async {
    List<AttendanceRecord> records = await SqliteService.getAllRecords();

    groupedData.clear();
    monthlyHours.clear();

    // 先按年月 -> 員工ID 分組
    for (var r in records) {
      String yearMonth = DateFormat('yyyy-MM').format(r.timestamp);
      groupedData.putIfAbsent(yearMonth, () => {});
      groupedData[yearMonth]!.putIfAbsent(r.name, () => []);
      groupedData[yearMonth]![r.name]!.add(r);
    }

    groupedData.forEach((yearMonth, empMap) {
      monthlyHours[yearMonth] = {};
      empMap.forEach((empName, recs) {
        // 按時間排序
        recs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // 每日分組
        Map<String, List<AttendanceRecord>> dailyRecords = {};
        for (var r in recs) {
          String day = DateFormat('yyyy-MM-dd').format(r.timestamp);
          dailyRecords.putIfAbsent(day, () => []);
          dailyRecords[day]!.add(r);
        }

        double monthTotal = 0;

        dailyRecords.forEach((day, recList) {
          recList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // 計算每日總工時
          double dailyHours = 0;
          for (int i = 0; i < recList.length - 1; i += 2) {
            if (recList[i].type == '上班' && recList[i + 1].type == '下班') {
              DateTime start = recList[i].timestamp;
              DateTime end = recList[i + 1].timestamp;

              // 依星期限制下班時間
              int weekday = end.weekday; // 1 = Mon, 7 = Sun
              DateTime limitEnd = end;
              if (weekday >= 1 && weekday <= 4) {
                if (end.hour > 21 || (end.hour == 21 && end.minute > 0)) {
                  limitEnd = DateTime(end.year, end.month, end.day, 21, 30);
                }
              } else if (weekday == 5 || weekday == 6) {
                if (end.hour > 21 || (end.hour == 21 && end.minute > 30)) {
                  limitEnd = DateTime(end.year, end.month, end.day, 22, 0);
                }
              } else if (weekday == 7) {
                if (end.hour > 21 || (end.hour == 21 && end.minute > 0)) {
                  limitEnd = DateTime(end.year, end.month, end.day, 21, 30);
                }
              }

              if (limitEnd.isBefore(start)) continue;

              int minutes = limitEnd.difference(start).inMinutes;

              // 半小時單位計算
              int halfHours = (minutes ~/ 30) * 30; // 不滿半小時不算
              dailyHours += halfHours / 60.0;
            }
          }

          monthTotal += dailyHours;
        });

        monthlyHours[yearMonth]![empName] = monthTotal;
      });
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('月統計報表')),
      body: groupedData.isEmpty
          ? const Center(child: Text('沒有打卡資料'))
          : ListView(
              children: groupedData.entries.map((ymEntry) {
                String yearMonth = ymEntry.key;
                Map<String, List<AttendanceRecord>> empMap = ymEntry.value;

                return ExpansionTile(
                  title: Text(
                    yearMonth,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: empMap.entries.map((empEntry) {
                    String empName = empEntry.key;
                    List<AttendanceRecord> recs = empEntry.value;
                    double totalHours = monthlyHours[yearMonth]?[empName] ?? 0;

                    // 每日分組
                    Map<String, List<AttendanceRecord>> dailyRecords = {};
                    for (var r in recs) {
                      String day = DateFormat('yyyy-MM-dd').format(r.timestamp);
                      dailyRecords.putIfAbsent(day, () => []);
                      dailyRecords[day]!.add(r);
                    }

                    return ExpansionTile(
                      title: Text(
                        '$empName - 當月總工時: ${totalHours.toStringAsFixed(2)} 小時',
                      ),
                      children: dailyRecords.entries.map((dayEntry) {
                        String day = dayEntry.key;
                        List<AttendanceRecord> dayList = dayEntry.value;

                        double dailyHours = 0;
                        for (int i = 0; i < dayList.length - 1; i += 2) {
                          if (dayList[i].type == '上班' &&
                              dayList[i + 1].type == '下班') {
                            DateTime start = dayList[i].timestamp;
                            DateTime end = dayList[i + 1].timestamp;

                            int weekday = end.weekday;
                            DateTime limitEnd = end;
                            if (weekday >= 1 && weekday <= 4) {
                              if (end.hour > 21 ||
                                  (end.hour == 21 && end.minute > 0)) {
                                limitEnd = DateTime(
                                  end.year,
                                  end.month,
                                  end.day,
                                  21,
                                  30,
                                );
                              }
                            } else if (weekday == 5 || weekday == 6) {
                              if (end.hour > 21 ||
                                  (end.hour == 21 && end.minute > 30)) {
                                limitEnd = DateTime(
                                  end.year,
                                  end.month,
                                  end.day,
                                  22,
                                  0,
                                );
                              }
                            } else if (weekday == 7) {
                              if (end.hour > 21 ||
                                  (end.hour == 21 && end.minute > 0)) {
                                limitEnd = DateTime(
                                  end.year,
                                  end.month,
                                  end.day,
                                  21,
                                  30,
                                );
                              }
                            }

                            if (limitEnd.isBefore(start)) continue;

                            int minutes = limitEnd.difference(start).inMinutes;
                            int halfHours = (minutes ~/ 30) * 30;
                            dailyHours += halfHours / 60.0;
                          }
                        }

                        return ListTile(
                          title: Text(
                            '${dayList.map((e) => e.type).join(' / ')}',
                            style: TextStyle(
                              color: dayList.any((e) => e.isManual)
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '日期: $day - 當日工時: ${dailyHours.toStringAsFixed(2)} 小時',
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
