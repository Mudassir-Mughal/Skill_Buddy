

import 'package:skill_buddy_fyp/Models/userprofile.dart';

class Instructor extends Userprofile {
  final List<String> skillsOffered;
  final int experienceYears;

  Instructor({
    required String uid,
    required String fullname,
    required String gender,
    required String education,
    required String phone,
    required String country,
    required this.skillsOffered,
    required this.experienceYears,
  }) : super(
    uid: uid,
    fullname: fullname,
    gender: gender,
    education: education,
    phone: phone,
    country: country,
    role: 'instructor',
  );

  factory Instructor.fromMap(String uid, Map<String, dynamic> data) {
    return Instructor(
      uid: uid,
      fullname: data['fullname'],
      gender: data['gender'],
      education: data['education'],
      phone: data['phone'],
      country: data['country'],
      skillsOffered: List<String>.from(data['skillsOffered'] ?? []),
      experienceYears: data['experienceYears'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'skillsOffered': skillsOffered,
        'experienceYears': experienceYears,
      });
  }
}
