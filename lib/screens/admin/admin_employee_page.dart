// 編輯員工資料頁面admin_employee_page.dart
// 管理員管理員工資料的頁面，包括新增、編輯、刪除員工
import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';

class AdminEmployeePage extends StatefulWidget {
  const AdminEmployeePage({super.key});

  @override
  _AdminEmployeePageState createState() => _AdminEmployeePageState();
}

class _AdminEmployeePageState extends State<AdminEmployeePage> {
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    // 讀取所有員工
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    // 從資料庫載入員工
    final data = await SqliteService.getAllEmployees();
    setState(() {
      employees = data;
    });
  }

  void _showEmployeeDialog({int? id, String? name}) {
    // 彈窗新增/編輯
    final TextEditingController controller = TextEditingController(
      text: name ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(id == null ? '新增員工' : '編輯員工'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '員工姓名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                if (id == null) {
                  await SqliteService.addEmployee(newName);
                } else {
                  await SqliteService.updateEmployee(id, newName);
                }
                Navigator.pop(context);
                _loadEmployees();
              },
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  void _deleteEmployee(int id) async {
    // 刪除員工（含確認對話框）
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除這位員工嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SqliteService.deleteEmployee(id);
      _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('員工管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEmployeeDialog(),
          ),
        ],
      ),
      body: employees.isEmpty
          ? const Center(child: Text('沒有員工資料'))
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (_, index) {
                final emp = employees[index];
                return ListTile(
                  title: Text('${emp['name']} (ID: ${emp['id']})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEmployeeDialog(
                          id: emp['id'],
                          name: emp['name'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteEmployee(emp['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
