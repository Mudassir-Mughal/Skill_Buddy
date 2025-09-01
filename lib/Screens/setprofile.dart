import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home.dart';
import 'StudentHome.dart';
import 'home.dart';
import 'theme.dart';

class SetProfilePage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final bool cameFromProfilePage;
  final bool isFromSignUp;

  const SetProfilePage({
    Key? key,
    this.existingData,
    this.cameFromProfilePage = false,
    this.isFromSignUp = false,
  }) : super(key: key);

  @override
  _SetProfilePageState createState() => _SetProfilePageState();
}

class _SetProfilePageState extends State<SetProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullname = TextEditingController();
  final _phoneController = TextEditingController();
  final _educationController = TextEditingController();
  final _countryController = TextEditingController();
  String? _gender = "Male";
  String selectedRole = "Student";

  @override
  void dispose() {
    _countryController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  final List<String> allSkills = [
    'Graphic Design',
    'Flutter Development',
    'Python Programming',
    'Freelancing',
    'SEO',
    'Video Editing',
    'Web Development',
    'Marketing',
  ];

  List<String> selectedTeachSkills = [];
  List<String> selectedLearnSkills = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _fullname.text = widget.existingData!["Fullname"] ?? " ";
      _phoneController.text = widget.existingData!['phone'] ?? '';
      _countryController.text = widget.existingData!['country'] ?? '';
      _gender = widget.existingData!['gender'] ?? '';
      selectedRole = widget.existingData!['role'] ?? 'Student';
      _educationController.text = widget.existingData!['education'] ?? '';
      selectedTeachSkills = List<String>.from(widget.existingData!['skillsToTeach'] ?? []);
      selectedLearnSkills = List<String>.from(widget.existingData!['skillsToLearn'] ?? []);
    }
  }

  final _auth = FirebaseAuth.instance;

  void _toggleSkill(List<String> list, String skill) {
    setState(() {
      list.contains(skill) ? list.remove(skill) : list.add(skill);
    });
  }

  bool isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^(03\d{9}|\+923\d{9})$');
    return regex.hasMatch(phone);
  }

  Widget _buildSkillChips(List<String> selectedList, bool isTeachList) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: allSkills.map((skill) {
        final isSelected = selectedList.contains(skill);
        return FilterChip(
          label: Text(skill),
          selected: isSelected,
          selectedColor: AppColors.primary.withOpacity(0.25),
          backgroundColor: AppColors.card,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          onSelected: (_) {
            _toggleSkill(isTeachList ? selectedTeachSkills : selectedLearnSkills, skill);
          },
        );
      }).toList(),
    );
  }

  Future<void> _saveProfile() async {
    final phone = _phoneController.text.trim();

    if (!isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number')),
      );
      return;
    }

    // Only gather skills according to role
    List<String> teachSkills = [];
    List<String> learnSkills = [];
    if (selectedRole == 'Instructor' || selectedRole == 'Both') {
      teachSkills = selectedTeachSkills;
    }
    if (selectedRole == 'Student' || selectedRole == 'Both') {
      learnSkills = selectedLearnSkills;
    }

    final teachSkillsSet = teachSkills.toSet();
    final learnSkillsSet = learnSkills.toSet();
    final commonSkills = teachSkillsSet.intersection(learnSkillsSet);

    if (commonSkills.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skills to Teach and Learn cannot be the same')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user != null) {
      final userData = {
        'uid': user.uid,
        "Fullname": _fullname.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        "role": selectedRole,
        'education': _educationController.text.trim(),
        'country': _countryController.text.trim(),
        'email': user.email ?? '',
        'skillsToTeach': teachSkills,
        'skillsToLearn': learnSkills,
        'profileSet': true,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile successfully updated!"),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.cameFromProfilePage) {
        Navigator.pop(context);
      } else {
        if (selectedRole.toLowerCase() == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Up Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Greeting Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Welcome , ${user?.email ?? 'User'}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Input Fields
              TextFormField(
                controller: _fullname,
                decoration: _buildInputDecoration('Full Name'),
                keyboardType: TextInputType.text,
                validator: (value) => value!.isEmpty ? 'Enter your Full name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: _buildInputDecoration('Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gender,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role Dropdown (chips logic depends on this)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500),
                    items: const [
                      DropdownMenuItem(value: 'Student', child: Text('Student')),
                      DropdownMenuItem(value: 'Instructor', child: Text('Instructor')),
                      DropdownMenuItem(value: 'Both', child: Text('Both')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Country Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _countryController.text.isNotEmpty ? _countryController.text : null,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    dropdownColor: Colors.white,
                    hint: const Text("Select Country"),
                    style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500),
                    items: [
                      'Pakistan',
                      'India',
                      'USA',
                      'UK',
                      'Canada',
                      'Germany',
                      'Australia',
                      'China',
                      'UAE',
                      'Saudi Arabia',
                    ].map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _countryController.text = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Education Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _educationController.text.isNotEmpty ? _educationController.text : null,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    dropdownColor: Colors.white,
                    hint: const Text("Select Education"),
                    style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500),
                    items: [
                      'High School',
                      'Intermediate',
                      'Bachelor\'s',
                      'Master\'s',
                      'PhD',
                      'Diploma',
                      'Short Course',
                    ].map((degree) {
                      return DropdownMenuItem(
                        value: degree,
                        child: Text(degree),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _educationController.text = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Skills to Learn (conditional, with chips style)
              if (selectedRole == 'Student' || selectedRole == 'Both') ...[
                const Text(
                  'Skills You Want to Learn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 10),
                _buildSkillChips(selectedLearnSkills, false),
                const SizedBox(height: 30),
              ],

              // Skills to Teach (conditional, with chips style)
              if (selectedRole == 'Instructor' || selectedRole == 'Both') ...[
                const Text(
                  'Skills You Can Teach',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 10),
                _buildSkillChips(selectedTeachSkills, true),
                const SizedBox(height: 30),
              ],

              /// Save Button
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Save & Continue', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}