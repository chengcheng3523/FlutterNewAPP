// 用來封裝「員工資料」的資料模型employee.dart
class Employee {
  String employeeId; // 員工編號
  String name; // 員工姓名

  Employee({required this.employeeId, this.name = ''});

  // 轉成 Map，方便存入資料庫
  Map<String, dynamic> toMap() {
    return {'employeeId': employeeId, 'name': name};
  }

  // 從 Map 生成 Employee 物件
  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(employeeId: map['employeeId'], name: map['name'] ?? '');
  }
}
