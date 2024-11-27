import 'package:flutter/material.dart';
import 'database_helper.dart';

class CreateAccountPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  CreateAccountPage({
    required this.isDarkMode,
    required this.toggleTheme,
  });

  void _createAccount(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      final dbHelper = DatabaseHelper();
      try {
        // Masukkan data user ke SQLite
        int id = await dbHelper.insertUser(username, password);

        // Log ke konsol run (Run Console)
        debugPrint('[Run Console] Akun berhasil dibuat dengan ID: $id, Username: $username');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akun berhasil dibuat!')),
        );
        Navigator.pop(context); // Kembali ke halaman login
      } catch (e) {
        debugPrint('[Run Console] Error: Username sudah digunakan!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username sudah digunakan!')),
        );
      }
    } else {
      debugPrint('[Run Console] Error: Semua kolom harus diisi!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom harus diisi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Akun'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.brightness_7 : Icons.brightness_2),
            onPressed: toggleTheme,
            tooltip: isDarkMode ? 'Mode Terang' : 'Mode Gelap',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _createAccount(context),
              child: Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
