import 'package:flutter/material.dart';
import 'database_helper.dart';

class CreateAccountPage extends StatelessWidget {
  // Controller untuk input username dan password
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  // Konstruktor untuk menerima parameter mode gelap dan fungsi toggle tema
  CreateAccountPage({
    required this.isDarkMode,
    required this.toggleTheme,
  });

  // Fungsi untuk membuat akun baru
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

        // Tampilkan pesan sukses dan kembali ke halaman login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akun berhasil dibuat!')),
        );
        Navigator.pop(context);
      } catch (e) {
        // Tampilkan pesan error jika username sudah digunakan
        debugPrint('[Run Console] Error: Username sudah digunakan!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username sudah digunakan!')),
        );
      }
    } else {
      // Tampilkan pesan error jika ada kolom yang kosong
      debugPrint('[Run Console] Error: Semua kolom harus diisi!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom harus diisi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buat Akun',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark ? Colors.grey[850] : Theme.of(context).primaryColor,
        actions: [
          // Tombol untuk mengubah tema
          IconButton(
            icon: Icon(isDark ? Icons.brightness_7 : Icons.brightness_2),
            onPressed: toggleTheme,
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Latar belakang gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [Colors.black54, Colors.black87] : [Colors.purpleAccent, Colors.deepPurple],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Gambar header
                Image.asset(
                  'assets/create_account_header.png', // Pastikan gambar ini ada di folder assets
                  height: 150,
                ),
                SizedBox(height: 20),
                // Input untuk username
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.black), // Ubah warna label menjadi hitam
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: Colors.black), // Ubah ikon menjadi hitam
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  style: TextStyle(color: Colors.black), // Ubah teks menjadi hitam
                ),
                SizedBox(height: 20),
                // Input untuk password
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black), // Ubah warna label menjadi hitam
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Colors.black), // Ubah ikon menjadi hitam
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  obscureText: true,
                  style: TextStyle(color: Colors.black), // Ubah teks menjadi hitam
                ),
                SizedBox(height: 20),
                // Tombol untuk membuat akun
                ElevatedButton(
                  onPressed: () => _createAccount(context),
                  child: Text(
                    'Buat Akun',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.purpleAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
