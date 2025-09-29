// 資料庫操作服務層 (Database Service)sqlite_service.dart
// 負責打卡紀錄與員工資料的 CRUD
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// import '../models/employee.dart';
import '../models/attendance_record.dart';

class SqliteService {
  static Database? _database;

  // 取得資料庫實例，若未初始化則建立資料庫
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // 初始化資料庫及資料表
  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 建立打卡紀錄表
        await db.execute('''
          CREATE TABLE records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employeeId TEXT,
            name TEXT,
            timestamp TEXT,
            type TEXT
          )
        ''');
        // 建立員工表
        await db.execute('''
          CREATE TABLE employees(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // ===== 打卡紀錄相關操作 =====
  static Future<int> insertRecord(AttendanceRecord record) async {
    final db = await database;
    return await db.insert('records', record.toMap());
  }

  static Future<List<AttendanceRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.rawQuery('''
    SELECT records.id, records.employeeId, employees.name, records.timestamp, records.type
    FROM records
    LEFT JOIN employees ON records.employeeId = employees.id -- ⚠ 如果 employees 沒有 employeeId，就要改成 employees.id
    ORDER BY records.timestamp DESC
  ''');

    return maps.map((e) => AttendanceRecord.fromMap(e)).toList();
  }

  static Future<int> updateRecord(AttendanceRecord record) async {
    final db = await database;
    return await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  static Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  // ===== 員工 CRUD 操作 =====
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final db = await database;
    return db.query('employees', orderBy: 'id');
  }

  static Future<void> addEmployee(String name) async {
    final db = await database;
    await db.insert('employees', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateEmployee(int id, String name) async {
    final db = await database;
    await db.update(
      'employees',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
