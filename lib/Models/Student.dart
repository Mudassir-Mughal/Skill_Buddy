

import 'package:skill_buddy_fyp/Models/userprofile.dart';

class Student extends Userprofile {
  final List<String> enrolledSkills;

  Student({
    required String uid,
    required String fullname,
    required String gender,
    required String education,
    required String phone,
    required String country,
    required this.enrolledSkills,
  }) : super(
    uid: uid,
    fullname: fullname,
    gender: gender,
    education: education,
    phone: phone,
    country: country,
    role: 'student',
  );

  factory Student.fromMap(String uid, Map<String, dynamic> data) {
    return Student(
      uid: uid,
      fullname: data['fullname'],
      gender: data['gender'],
      education: data['education'],
      phone: data['phone'],
      country: data['country'],
      enrolledSkills: List<String>.from(data['enrolledSkills'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll({
        'enrolledSkills': enrolledSkills,
      });
  }
}
