// 員工補打卡紀錄
import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../services/sqlite_service.dart';
import 'package:intl/intl.dart';

class ManualAttendance extends StatefulWidget {
  @override
  _ManualAttendanceState createState() => _ManualAttendanceState();
}

class _ManualAttendanceState extends State<ManualAttendance> {
  final TextEditingController _idController = TextEditingController();

  DateTime? _selectedDateTime; // ⭐ 這裡宣告，避免 undefined
  String _type = '上班';

  Future<void> _pickDateTime() async {
    // 選日期
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    // 選時間
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final empId = _idController.text.trim();

    if (empId.isEmpty || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('請輸入員工編號並選擇時間')),
      );
      return;
    }

    final record = AttendanceRecord(
      employeeId: empId,
      timestamp: _selectedDateTime!,
      type: _type,
      isManual: true, // ⭐ 標記為補打卡
    );

    await SqliteService.insertRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('補打卡成功！')),
      );
    }

    _idController.clear();
    setState(() {
      _selectedDateTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("補打卡")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: '員工編號'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateTime == null
                        ? "尚未選擇時間"
                        : "選擇時間：${DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!)}",
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDateTime,
                  child: Text("選擇時間"),
                ),
              ],
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _type,
              items: ['上班', '下班'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _type = val!;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                child: Text("送出"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}