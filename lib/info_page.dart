import 'package:flutter/material.dart';
import 'confidentiality_page.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const SettingsPage({Key? key, required this.userData, required this.token}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки приложения', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),
              _buildSettingsSection(
                context,
                'Учетные данные',
                [
                  _buildSettingsItem(
                    context,
                    icon: Icons.lock,
                    title: 'Конфиденциальность',
                    subtitle: 'Настройки конфиденциальности',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfidentialityPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.white.withOpacity(0.1),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white70)) : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Colors.white24),
      ],
    );
  }
}
