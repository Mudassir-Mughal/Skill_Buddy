import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'setprofile.dart';
import 'theme.dart';

const String cloudName = "dthkthzzf";
const String uploadPreset = "unsigned_preset";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<String?> _uploadToCloudinary(Uint8List fileBytes, String fileName) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        print("Cloudinary Upload Failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;

      final imageUrl = await _uploadToCloudinary(fileBytes, fileName);

      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "photoUrl": imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image upload failed!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No user data found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (data['photoUrl'] != null &&
                                data['photoUrl'].toString().isNotEmpty)
                                ? NetworkImage(data['photoUrl'])
                                : null,
                            child: (data['photoUrl'] == null ||
                                data['photoUrl'].toString().isEmpty)
                                ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                                : null,
                          ),
                          IconButton(
                            icon: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                            onPressed: () => _pickAndUploadImage(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Name
                      Text(
                        data['Fullname']?.toString().isNotEmpty == true
                            ? data['Fullname']
                            : '-',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFF222244),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Email
                      Text(
                        data['email'] ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Profile Details
                      _profileDetailCard(Icons.phone, "Phone", data['phone'] ?? ''),
                      _profileDetailCard(Icons.male, "Gender", data['gender'] ?? ''),
                      _profileDetailCard(Icons.flag, "Country", data['country'] ?? ''),
                      _profileDetailCard(Icons.school, "Education", data['education'] ?? ''),
                      _profileDetailCard(Icons.star, "Skill You Can Teach",
                          (data['skillsToTeach'] is List) ? (data['skillsToTeach'] as List).join(', ') : ''),
                      _profileDetailCard(Icons.lightbulb, "Skill You Want to Learn",
                          (data['skillsToLearn'] is List) ? (data['skillsToLearn'] as List).join(', ') : ''),

                      const SizedBox(height: 30),

                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SetProfilePage(
                                  existingData: data,
                                  cameFromProfilePage: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // --- Delete Account Button REMOVED ---
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileDetailCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E6F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : "$title: $value",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}