// 月報表統計頁monthly_report.dart
import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';
import '../../models/attendance_record.dart';
import 'package:intl/intl.dart';
import '../../services/export_service.dart';

class MonthlyReport extends StatefulWidget {
  const MonthlyReport({Key? key}) : super(key: key);

  @override
  _MonthlyReportState createState() => _MonthlyReportState();
}

// 自動判斷規則範例（早班固定 09:30）
class AttendanceChecker {
  static bool isLate(AttendanceRecord record) {
    // 只判上班時間
    if (record.type != '上班') return false;

    // 只判早班上班時間（例如 09:30 前打卡才算早班）
    if (record.timestamp.hour > 10) return false; // 下午/晚上班不判遲到

    return record.timestamp.isAfter(
      DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
        9,
        30,
      ),
    );
  }

  static bool isEarlyLeave(AttendanceRecord record) {
    // 只判下班時間
    if (record.type != '下班') return false;
    // 假設早班最少工作 8 小時，可自行調整規則
    final start = DateTime(
      record.timestamp.year,
      record.timestamp.month,
      record.timestamp.day,
      9,
      30,
    );
    return record.timestamp.isBefore(start.add(const Duration(hours: 8)));
  }

  static bool isMissingPair(List<AttendanceRecord> dayRecords) {
    // 如果每天上班/下班不成對，表示缺卡
    int checkIn = dayRecords.where((r) => r.type == '上班').length;
    int checkOut = dayRecords.where((r) => r.type == '下班').length;
    return checkIn != checkOut;
  }

  static bool hasAbnormal(List<AttendanceRecord> dayRecords) {
    return dayRecords.any((r) => r.isManual == 1) ||
        dayRecords.any(isLate) ||
        dayRecords.any(isEarlyLeave) ||
        isMissingPair(dayRecords);
  }
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

              // 計算實際工作時數（分鐘差）
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
      appBar: AppBar(
        title: const Text('月統計報表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final records = await SqliteService.getAllRecords();
              final path = await ExportService.exportExcel(records);
              await ExportService.shareFile(path);
            },
          ),
        ],
      ),
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

                        // 每兩筆資料為一組（上班 / 下班）
                        for (int i = 0; i < dayList.length - 1; i += 2) {
                          if (dayList[i].type == '上班' &&
                              dayList[i + 1].type == '下班') {
                            DateTime start = dayList[i].timestamp; // 上班時間
                            DateTime end = dayList[i + 1].timestamp; // 下班時間

                            // 直接用上下班差值
                            int minutes = end.difference(start).inMinutes;

                            int weekday = end.weekday;
                            // 預設下班時間為打卡時間
                            DateTime limitEnd = end;
                            // 判斷平日、週五六、週日的最晚可計算工時
                            if (weekday >= 1 && weekday <= 4) {
                              // 週一到週四最晚算到 21:30
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
                              // 週五、週六最晚算到 22:00
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
                              // 週日最晚算到 21:30
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

                            // 避免修正後的下班時間早於上班時間
                            if (limitEnd.isBefore(start)) continue;

                            int halfHours = (minutes ~/ 30) * 30; // 以半小時計
                            dailyHours += halfHours / 60.0;
                          }
                        }

                        return ListTile(
                          title: Text(
                            '${dayList.map((e) => DateFormat('HH:mm').format(e.timestamp)).join(' / ')}',
                            style: TextStyle(
                              color:
                                  dayList.any(
                                    (e) => e.isManual,
                                  ) // 注意這裡使用布林值而非 == 1
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
