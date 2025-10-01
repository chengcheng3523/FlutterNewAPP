// 編輯員工資料頁面admin_employee_page.dart
// 管理員管理員工資料的頁面，包括新增、編輯、刪除員工
import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';

class AdminEmployeePage extends StatefulWidget {
  const AdminEmployeePage({super.key});

  @override
  AdminEmployeePageState createState() => AdminEmployeePageState();
}

class AdminEmployeePageState extends State<AdminEmployeePage> {
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
    // final TextEditingController controller = TextEditingController(text: name ?? '',);
    final TextEditingController nameController = TextEditingController(text: name ?? '');
    final TextEditingController idController = TextEditingController(text: id?.toString() ?? '');
    String? idError; // 用來顯示紅色提示

    showDialog(
      context: context,
      builder: (_) {
        // 用 StatefulBuilder 讓對話框內可動態更新
        return StatefulBuilder(
          builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(id == null ? '新增員工' : '編輯員工'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 員工姓名
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '員工姓名'),
              ),
              const SizedBox(height: 10),
              // 員工ID（新增才可編輯，編輯時不可更改）
              TextField(
                controller: idController,
                decoration: InputDecoration(
                    labelText: '員工編號',
                    errorText: idError, // 顯示紅色提示
                ),
                keyboardType: TextInputType.number,
                enabled: id == null,
                onChanged: (value) {
                  if (id == null) {
                    final newId = int.tryParse(value.trim());
                    if (newId != null && employees.any((e) => e['id'] == newId)) {
                      setDialogState(() {
                        idError = '此編號已存在';
                      });
                    } else {
                      setDialogState(() {
                        idError = null;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                // final newName = controller.text.trim();
                final newName = nameController.text.trim();
                final newIdText = idController.text.trim();

                // if (newName.isEmpty) return;

                if (newName.isEmpty || newIdText.isEmpty || idError != null) return;

                final newId = int.tryParse(newIdText);
                if (newId == null) return;

                // 檢查新增時 ID 是否重複
                if (id == null) {
                  // 新增
                  await SqliteService.addEmployeeWithId(newId, newName);
                } else {
                  // 編輯名稱
                  await SqliteService.updateEmployee(id, newName);
                }

                if (!mounted) return;
                Navigator.pop(context);
                _loadEmployees();
              },
              child: const Text('確認'),
            ),
          ],
        );
          },
        );
      },
    );
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
                    ],
                  ),
                );
              },
            ),
    );
  }
}
