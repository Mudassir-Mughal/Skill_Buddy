import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _skills = [];
  bool _fetched = false;

  List<Map<String, dynamic>> get skills => _skills;

  Future<void> fetchSkills() async {
    if (_fetched) return; // Already fetched, don't reload!
    final snapshot = await FirebaseFirestore.instance.collection('skills').get();
    List<Map<String, dynamic>> allSkills = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      allSkills.add({...data, 'skillId': doc.id});
    }
    _skills = allSkills;
    _fetched = true;
    notifyListeners();
  }

  // Optional: For refreshing skills
  Future<void> refreshSkills() async {
    _fetched = false;
    await fetchSkills();
  }
}