// 用來封裝「員工資料」的資料模型employee.dart
class Employee {
  String employeeId;
  String name;

  Employee({required this.employeeId, this.name = ''});

  Map<String, dynamic> toMap() {
    return {'employeeId': employeeId, 'name': name};
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(employeeId: map['employeeId'], name: map['name'] ?? '');
  }
}
