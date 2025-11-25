import 'package:flutter/material.dart';
import 'theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle("Account"),
          const SizedBox(height: 10),
          _buildSettingCard(
            icon: Icons.lock_outline_rounded,
            title: "Change Password",
            onTap: () {
              // TODO: Navigate to Change Password Page
            },
          ),
          const SizedBox(height: 28),
          _sectionTitle("Preferences"),
          const SizedBox(height: 10),
          _buildSettingCard(
            icon: Icons.notifications_none_rounded,
            title: "Notification Preferences",
            onTap: () {
              // TODO: Navigate to Notification Preferences Page
            },
          ),
          const SizedBox(height: 10),
          _buildSettingCard(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Settings",
            onTap: () {
              // TODO: Navigate to Privacy Settings Page
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppColors.primary, size: 26),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
