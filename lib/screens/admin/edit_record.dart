// 修改/刪除紀錄頁edit_record.dart
import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../services/sqlite_service.dart';

class EditRecord extends StatefulWidget {
  final AttendanceRecord record;
  EditRecord({required this.record});

  @override
  _EditRecordState createState() => _EditRecordState();
}

class _EditRecordState extends State<EditRecord> {
  late TextEditingController _idController;
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.record.employeeId);
    _typeController = TextEditingController(text: widget.record.type);
  }

  void _save() async {
    widget.record.employeeId = _idController.text.trim();
    widget.record.type = _typeController.text.trim();
    await SqliteService.updateRecord(widget.record);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('修改紀錄')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: '員工編號'),
            ),
            TextField(
              controller: _typeController,
              decoration: InputDecoration(labelText: '上/下班'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text('儲存')),
          ],
        ),
      ),
    );
  }
}
