import 'package:flutter/material.dart';
import '../Service/api_service.dart';
import 'Addskill.dart';
import 'home.dart';
import 'theme.dart';

class MySkillsPage extends StatefulWidget {
  final String userId;
  const MySkillsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MySkillsPage> createState() => _MySkillsPageState();
}

class _MySkillsPageState extends State<MySkillsPage> {
  late Future<List<Map<String, dynamic>>> _mySkills;

  @override
  void initState() {
    super.initState();
    _mySkills = _fetchUserSkills();
  }

  Future<List<Map<String, dynamic>>> _fetchUserSkills() async {
    final userId = widget.userId;
    if (userId.isEmpty) return [];
    final result = await ApiService.getSkillsByUser(userId);
    return result;
  }

  Future<void> _deleteSkill(String skillId) async {
    final success = await ApiService.deleteSkill(skillId);
    if (success) {
      setState(() {
        _mySkills = _fetchUserSkills();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill deleted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete skill.')),
      );
    }
  }

  void _showDeleteConfirmation(String skillId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 30),
            const SizedBox(width: 8),
            const Text('Delete Skill', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this skill? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteSkill(skillId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _mySkills,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final skills = snapshot.data ?? [];

          if (skills.isEmpty) {
            return const Center(child: Text("You haven't added any skills yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  title: Text(
                    skill['title'] ?? 'Untitled Skill',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    skill['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded),
                        color: AppColors.primary,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddSkillPage(
                                existingData: skill,
                                skillId: skill['skillId'],
                                userId: widget.userId,
                              ),
                            ),
                          );
                          setState(() {
                            _mySkills = _fetchUserSkills();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(skill['skillId']);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}