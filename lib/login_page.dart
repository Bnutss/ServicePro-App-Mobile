import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'menu_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;
  String _welcomeMessage = 'ServicePro';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkBiometricPreference();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (e) {
      print('Ошибка при проверке биометрии: $e');
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _checkBiometricPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? useBiometrics = prefs.getBool('useBiometrics');

    if (useBiometrics ?? false) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Пожалуйста, пройдите аутентификацию',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    } catch (e) {
      print('Ошибка при биометрической аутентификации: $e');
      setState(() {
        _isAuthenticating = false;
      });
    }
    if (!mounted) return;

    if (authenticated) {
      await _loginWithBiometrics();
    } else {
      _showError('Биометрическая аутентификация не удалась');
    }
  }

  Future<void> _loginWithBiometrics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      await _fetchUserData(token);
    } else {
      _showError('Токен не найден');
    }
  }

  Future<void> _fetchUserData(String token) async {
    try {
      final userResponse = await http.get(
        Uri.parse('https://servicepro.pythonanywhere.com/api/user/'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(utf8.decode(userResponse.bodyBytes));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => MenuPage(userData: userData, token: token)),
        );
      } else if (userResponse.statusCode == 401) {
        await _refreshToken();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final newToken = prefs.getString('access_token');
        if (newToken != null) {
          await _fetchUserData(newToken);
        } else {
          _showError('Не удалось обновить токен');
        }
      } else {
        _showError('Не удалось получить данные пользователя.');
      }
    } catch (e) {
      print('Ошибка сети при получении данных пользователя: $e');
      _showError('Ошибка сети при получении данных пользователя.');
    }
  }

  Future<void> _refreshToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken != null) {
      try {
        final response = await http.post(
          Uri.parse('https://servicepro.pythonanywhere.com/api/token/refresh/'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refresh': refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          final refreshData = json.decode(utf8.decode(response.bodyBytes));
          final newAccessToken = refreshData['access'];
          await prefs.setString('access_token', newAccessToken);
        } else {
          _showError('Не удалось обновить токен');
        }
      } catch (e) {
        print('Ошибка сети при обновлении токена: $e');
        _showError('Ошибка сети при обновлении токена.');
      }
    } else {
      _showError('Refresh token not found');
    }
  }

  Future<void> _login() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Введите логин и пароль');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://servicepro.pythonanywhere.com/api/login/'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final loginData = json.decode(utf8.decode(response.bodyBytes));
        final accessToken = loginData['access'];
        final refreshToken = loginData['refresh'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setBool('useBiometrics', true);

        await _fetchUserData(accessToken);
      } else {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final String errorMessage = responseData['detail'] ?? 'Ошибка входа';
        _showError(errorMessage);
      }
    } catch (e) {
      print('Ошибка сети при входе: $e');
      _showError('Ошибка сети при входе.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildBiometricButton() {
    if (_isAuthenticating) {
      return const CircularProgressIndicator();
    } else if (_canCheckBiometrics) {
      return ElevatedButton(
        onPressed: _authenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: const Text(
          'Войти с помощью биометрии',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 10),
                  Image.asset('assets/icon/logo.png', width: 200),
                  const SizedBox(height: 20),
                  Text(
                    _welcomeMessage,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Логин',
                      prefixIcon:
                      const Icon(Icons.person, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Войти',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBiometricButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
