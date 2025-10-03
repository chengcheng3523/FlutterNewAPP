// export_service.dart匯出服務層
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance_record.dart';

class ExportService {
  /// 匯出 CSV，回傳檔案路徑
  static Future<String> exportCsv(List<AttendanceRecord> records) async {
    List<List<String>> rows = [
      ['姓名', '日期', '上班/下班', '時間', '是否異常'],
    ];

    for (var r in records) {
      rows.add([
        r.name,
        r.timestamp.toIso8601String(),
        r.type,
        '${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}',
        r.isManual == 1 ? '是' : '否', // 假設 isManual 是 int
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/attendance_export.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    print('CSV 匯出成功：$path');
    return path;
  }

  /// 匯出 Excel，回傳檔案路徑
  static Future<String> exportExcel(List<AttendanceRecord> records) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['打卡紀錄'];

    sheet.appendRow(['姓名', '日期', '上班/下班', '時間', '是否異常']);

    for (var r in records) {
      sheet.appendRow([
        r.name,
        r.timestamp.toIso8601String(),
        r.type,
        '${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}',
        r.isManual == 1 ? '是' : '否',
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/attendance_export.xlsx';
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      print('Excel 匯出成功：$path');
    }

    return path;
  }

  /// 分享檔案
  static Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: '打卡資料匯出');
  }
}
