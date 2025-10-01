//封裝「打卡紀錄」資料的資料模型attendance_record.dart
class AttendanceRecord {
  int? id; // 唯一編號
  String employeeId; // 員工編號
  String name; // 員工姓名 (JOIN 取得)
  DateTime timestamp; // 打卡時間
  String type; // 打卡類型 (上班/下班)
  bool isManual; // 新增：是否為補打卡

  AttendanceRecord({
    this.id,
    required this.employeeId,
    this.name = '',
    required this.timestamp,
    required this.type,
    this.isManual = false, // 預設 false
  });

  // 轉成 Map，方便存入資料庫
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isManual': isManual ? 1 : 0, // 存成整數
    };
  }

  // 從 Map 生成 AttendanceRecord 物件
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      employeeId: map['employeeId'],
      name: map['name'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      isManual: map['isManual'] == 1, // 轉回布林
    );
  }
}
