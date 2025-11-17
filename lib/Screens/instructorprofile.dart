import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme.dart';

class InstructorProfilePage extends StatelessWidget {
  final String instructorId;
  final String baseUrl;
  const InstructorProfilePage({super.key, required this.instructorId, required this.baseUrl});

  Future<Map<String, dynamic>?> fetchInstructor() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/$instructorId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Instructor Profile', style: TextStyle(color: AppColors.buttonText)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.buttonText),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchInstructor(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Instructor not found.'));
          }
          final instructor = snapshot.data!;

          // Profile photo url, update field name as per your Firestore
          final photoUrl = instructor['photoUrl'] ?? instructor['profilePhoto'];

          // Get skills arrays safely
          final skillsToTeach = (instructor['skillsToTeach'] as List<dynamic>?)?.whereType<String>().toList() ?? [];
          final skillsToLearn = (instructor['skillsToLearn'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Row(
                    children: [
                      photoUrl != null && photoUrl.toString().isNotEmpty
                          ? CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(photoUrl),
                        backgroundColor: AppColors.primary,
                      )
                          : const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: Colors.white, size: 34),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instructor['Fullname'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Dummy Rating
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                const Text(
                                  "4.7 ★",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Education
                  if (instructor['education'] != null && instructor['education'].toString().trim().isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.school, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            instructor['education'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  // Bio
                  if (instructor['bio'] != null && instructor['bio'].toString().trim().isNotEmpty)
                    Text(
                      instructor['bio'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  // Skills Want to Teach
                  if (skillsToTeach.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Skills Want to Teach",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: skillsToTeach.map((skill) => Chip(
                        label: Text(skill, style: const TextStyle(color: AppColors.primary)),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      )).toList(),
                    ),
                  ],
                  // Skills Want to Learn
                  if (skillsToLearn.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Skills Want to Learn",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: skillsToLearn.map((skill) => Chip(
                        label: Text(skill, style: const TextStyle(color: AppColors.primary)),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}