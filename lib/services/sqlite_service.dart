// 資料庫操作服務層 (Database Service)sqlite_service.dart
// 負責打卡紀錄與員工資料的 CRUD
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/attendance_record.dart';
import 'dart:math';

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
      version: 2, // ⭐ 設定版本號 (每次修改 schema 記得 +1)
      onCreate: (db, version) async {
        // 建立打卡紀錄表
        await db.execute('''
          CREATE TABLE records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employeeId TEXT,
            name TEXT,
            timestamp TEXT,
            type TEXT,
            isManual INTEGER NOT NULL DEFAULT 0 -- 新增：是否為補打卡
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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // ⭐ 從舊版本升級時，補上 isManual 欄位
          await db.execute(
            'ALTER TABLE records ADD COLUMN isManual INTEGER NOT NULL DEFAULT 0',
          );
        }
        // 👉 未來如果還要新增欄位，可以這樣加：
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE employees ADD COLUMN email TEXT');
        }
      },
    );
  }

  // ===== 打卡紀錄相關操作 =====
  static Future<int> insertRecord(AttendanceRecord record) async {
    final db = await database;
    return await db.insert('records', record.toMap());
  }

  /// 取得所有紀錄
  static Future<List<AttendanceRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.rawQuery('''
    SELECT records.id, records.employeeId, employees.name, records.timestamp, records.type, records.isManual
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

  // 刪除半年以前的打卡紀錄
  static Future<int> deleteOldRecords() async {
    final db = await database;
    final sixMonthsAgo = DateTime.now().subtract(Duration(days: 182));
    return await db.delete(
      'records',
      where: 'timestamp < ?',
      whereArgs: [sixMonthsAgo.toIso8601String()],
    );
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

  // 新增員工（指定 ID）
  static Future<void> addEmployeeWithId(int id, String name) async {
    final db = await database;
    await db.insert('employees', {
      'id': id,
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

  /// 插入測試資料（整個月）
  static Future<void> seedMonthlyTestData() async {
    final db = await database;
    await db.delete('records'); // 清空舊資料，方便測試

    final now = DateTime.now();
    final name = "測試員工";

    for (int day = 1; day <= 30; day++) {
      final date = DateTime(now.year, now.month, day);

      // 上班
      await db.insert('records', {
        'name': name,
        'type': '上班',
        'timestamp': DateTime(
          date.year,
          date.month,
          date.day,
          9,
          0,
        ).toIso8601String(),
        'isManual': 0,
      });

      // 下班
      await db.insert('records', {
        'name': name,
        'type': '下班',
        'timestamp': DateTime(
          date.year,
          date.month,
          date.day,
          18,
          0,
        ).toIso8601String(),
        'isManual': 0,
      });
    }
  }


  static Future<void> seedEmployeeCTestData() async {
    final db = await database;

    // 先清理原有 C 的紀錄
    await db.delete('records', where: 'name = ?', whereArgs: ['C']);

    // 2️⃣ 新增員工 C
    await db.insert('employees', {
      'id': 3,
      'name': 'C',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 九月份紀錄
    final records = [
      {'date': 3, 'on': '09:27', 'off': '21:27'},
      {'date': 4, 'on': '09:19', 'off': '21:16'},
      {'date': 5, 'on': '09:31', 'off': '22:00'}, //遲到
      {'date': 6, 'on': '09:27', 'off': '21:44'},
      {'date': 7, 'on': '09:27', 'off': '21:39'},
      {'date': 8, 'on': '16:51', 'off': '21:26'},
      {'date': 9, 'on': '16:40', 'off': '21:27'},
      {'date': 10, 'on': '09:27', 'off': '18:05'},
      {'date': 12, 'on': '09:28', 'off': '17:05'},
      {'date': 13, 'on': '10:22', 'off': '21:58'},
      {'date': 14, 'on': '10:22', 'off': '21:19'},
      {'date': 15, 'on': '16:50', 'off': '21:30'},
      {'date': 16, 'on': '16:53', 'off': '21:25'},
      {'date': 17, 'on': '09:32', 'off': '21:25'}, //遲到
      {'date': 19, 'on': '16:49', 'off': '22:03'},
      {'date': 20, 'on': '10:28', 'off': '21:54'},
      {'date': 21, 'on': '09:26', 'off': '20:01'},
      {'date': 22, 'on': '09:30', 'off': '21:20'},
      {'date': 24, 'on': '16:54', 'off': '21:15'},
      {'date': 25, 'on': '16:54', 'off': '21:15'},
      {'date': 26, 'on': '09:27', 'off': '21:44'},
      {'date': 28, 'on': '16:54', 'off': '21:15'},
      {'date': 29, 'on': '09:27', 'off': '21:39'},
    ];

    final year = DateTime.now().year;
    final month = 9;
    final random = Random();

    for (var rec in records) {
      // 隨機決定是否遲到/早退/缺卡
      bool onManual = random.nextInt(10) < 2; // 20% 機率上班異常
      bool offManual = random.nextInt(10) < 2; // 20% 機率下班異常

      // 上班
      final onTime = (rec['on'] as String).split(':'); // cast 為 String
      final onHour = int.parse(onTime[0]);
      final onMinute = int.parse(onTime[1]);
      final day = rec['date'] as int; // cast 為 int
      await db.insert('records', {
        'employeeId': '3', // 對應 employees.id
        'name': 'C',
        'type': '上班',
        'timestamp': DateTime(year, month, day, onHour, onMinute).toIso8601String(),
        'isManual': 1, // 標記補打卡或異常
      });

      // 下班
      final offTime = (rec['off'] as String).split(':');
      final offHour = int.parse(offTime[0]);
      final offMinute = int.parse(offTime[1]);
      await db.insert('records', {
        'employeeId': '3',
        'name': 'C',
        'type': '下班',
        'timestamp': DateTime(year, month, day, offHour, offMinute).toIso8601String(),
        'isManual': 1, // 標記補打卡或異常
      });
    }
  }

}
