//封裝「打卡紀錄」資料的資料模型attendance_record.dart
class AttendanceRecord {
  int? id;
  String employeeId; // 員工編號
  String name; // 員工姓名 (JOIN 取得)
  DateTime timestamp; // 打卡時間
  String type; // 打卡類型 (上班/下班)

  AttendanceRecord({
    this.id,
    required this.employeeId,
    this.name = '',
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      employeeId: map['employeeId'],
      name: map['name'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
    );
  }
}
