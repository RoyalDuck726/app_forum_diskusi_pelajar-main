import 'package:flutter/material.dart';
import 'home_page.dart';
import 'database_helper.dart';
import 'create_account_page.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  LoginPage({required this.toggleTheme, required this.isDarkMode});

  void _login(BuildContext context) async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      final dbHelper = DatabaseHelper();
      final user = await dbHelper.getUser(username);
      
      if (user != null && user['password'] == password) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username atau password salah!')),
        );
      }
    } else {
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
        title: Text('Login'),
        backgroundColor: isDark ? Colors.grey[850] : Colors.blue,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.brightness_7 : Icons.brightness_2),
            onPressed: toggleTheme,
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                onPressed: () => _login(context),
                child: Text('Login'),
              ),
              SizedBox(height: 10),
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
                child: Text('Buat Akun Baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
