import 'package:flutter/material.dart';
import 'home_page.dart';
import 'database_helper.dart';
import 'create_account_page.dart';

class LoginPage extends StatelessWidget {
  // Controller untuk input username dan password
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  // Konstruktor untuk menerima parameter mode gelap dan fungsi toggle tema
  LoginPage({required this.toggleTheme, required this.isDarkMode});

  // Fungsi untuk melakukan login
  void _login(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUser(username);
      
      if (user != null && user['password'] == password) {
        // Tandai pengguna sebagai login dan navigasi ke HomePage
        await dbHelper.setUserLoggedIn(username);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              currentUserId: username,
              userRole: user['role'],
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            ),
          ),
        );
      } else {
        // Tampilkan pesan error jika username atau password salah
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username atau password salah!')),
        );
      }
    } else {
      // Tampilkan pesan error jika ada kolom yang kosong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom harus diisi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.blue,
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
                colors: isDark ? [Colors.black54, Colors.black87] : [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gambar header
                  Image.asset(
                    'assets/login_header.png', 
                    height: 150,
                  ),
                  SizedBox(height: 20),
                  // Input untuk username
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Colors.black),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  // Input untuk password
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Colors.black),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  // Tombol untuk login
                  ElevatedButton(
                    onPressed: () => _login(context),
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: isDark ? Colors.grey[800] : Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Tombol untuk navigasi ke halaman pembuatan akun
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAccountPage(
                            isDarkMode: isDarkMode,
                            toggleTheme: toggleTheme,
                          ),
                        ),
                      );
                    },
                    child: Text('Buat Akun Baru', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
