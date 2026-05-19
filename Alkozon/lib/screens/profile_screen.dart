import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkozon/services/auth_service.dart';
import 'package:alkozon/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _photoPathKey = 'profile_photo_path';
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late Future<CurrentUserProfile?> _profileFuture;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUserProfile();
    _loadPhotoPath();
  }

  Future<void> _loadPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _photoPath = prefs.getString(_photoPathKey);
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoPathKey, picked.path);
    if (!mounted) return;
    setState(() {
      _photoPath = picked.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Colors.purpleAccent;

    return FutureBuilder<CurrentUserProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Twój profil",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: themeColor.withOpacity(0.15),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2.0),
              child: Container(color: themeColor.withOpacity(0.5), height: 2.0),
            ),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(snapshot.data, themeColor),
        );
      },
    );
  }

  Widget _buildBody(CurrentUserProfile? profile, Color themeColor) {
    final displayName = profile?.displayName ?? 'Pracownik';
    final email = profile?.email.isNotEmpty == true ? profile!.email : '-';
    final employeeId = profile?.id.toString() ?? '-';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: themeColor.withOpacity(0.2),
                      backgroundImage:
                          _photoPath != null && File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                      child:
                          _photoPath != null && File(_photoPath!).existsSync()
                          ? null
                          : Icon(Icons.person, size: 60, color: themeColor),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _pickPhoto,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: themeColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileRow(
                    icon: Icons.badge_outlined,
                    label: "ID Pracownika",
                    value: employeeId,
                    color: themeColor,
                  ),
                  const Divider(height: 32),
                  _buildProfileRow(
                    icon: Icons.email_outlined,
                    label: "Email służbowy",
                    value: email,
                    color: themeColor,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await _authService.logout();
                await _notificationService.initialize();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                "Wyloguj się",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
