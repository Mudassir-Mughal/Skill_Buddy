class Userprofile {
  final String uid;
  final String fullname;
  final String gender;
  final String education;
  final String phone;
  final String country;
  final String role; // 'student', 'instructor', 'both'

  Userprofile({
    required this.uid,
    required this.fullname,
    required this.gender,
    required this.education,
    required this.phone,
    required this.country,
    required this.role,
  });

  factory Userprofile.fromMap(String uid, Map<String, dynamic> data) {
    return Userprofile(
      uid: uid,
      fullname: data['fullname'] ?? '',
      gender: data['gender'] ?? '',
      education: data['education'] ?? '',
      phone: data['phone'] ?? '',
      country: data['country'] ?? '',
      role: data['role'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullname': fullname,
      'gender': gender,
      'education': education,
      'phone': phone,
      'country': country,
      'role': role,
    };
  }
}
