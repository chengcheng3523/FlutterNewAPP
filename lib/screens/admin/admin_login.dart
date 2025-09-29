// 管理員登入頁admin_login.dart
import 'package:flutter/material.dart';
import 'admin_home.dart';

class AdminLogin extends StatefulWidget {
  @override
  _AdminLoginState createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _login() {
    String username = _userController.text.trim();
    String password = _passController.text.trim();

    // 範例：固定帳密 admin / 1234
    if (username == 'admin' && password == '1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminHome()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('帳號或密碼錯誤')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('管理員登入')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: '帳號'),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(labelText: '密碼'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('登入')),
          ],
        ),
      ),
    );
  }
}
