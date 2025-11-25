import 'package:flutter/material.dart';
import '../Service/skilllist.dart';
import 'StudentHome.dart';
import 'theme.dart';
import 'package:skill_buddy_fyp/Screens/home.dart';
import '../Service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetProfilePage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final bool cameFromProfilePage;
  final bool isFromSignUp;
  final String? userId; // Pass userId from login/signup
  final bool hideBackButton;

  const SetProfilePage({
    super.key,
    this.existingData,
    this.cameFromProfilePage = false,
    this.isFromSignUp = false,
    this.userId,
    this.hideBackButton = false,
  });

  @override
  State<SetProfilePage> createState() => _SetProfilePageState();
}

class _SetProfilePageState extends State<SetProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullname = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _gender = 'Male';
  String selectedRole = 'Student';
  List<String> selectedTeachSkills = [];
  List<String> selectedLearnSkills = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _fullname.text = data['Fullname'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _countryController.text = data['country'] ?? '';
      _gender = data['gender'] ?? _gender;
      selectedRole = data['role'] ?? selectedRole;
      _educationController.text = data['education'] ?? '';
      selectedTeachSkills = List<String>.from(data['skillsToTeach'] ?? []);
      selectedLearnSkills = List<String>.from(data['skillsToLearn'] ?? []);
    }
  }

  @override
  void dispose() {
    _fullname.dispose();
    _phoneController.dispose();
    _educationController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _toggleSkill(List<String> list, String skill) {
    setState(() {
      if (list.contains(skill)) {
        list.remove(skill);
      } else {
        list.add(skill);
      }
    });
  }

  bool isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^(03\d{9}|\+923\d{9})$');
    return regex.hasMatch(phone);
  }

  Widget _buildSkillChips(List<String> selectedList, bool isTeachList) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;
      return Wrap(
        spacing: isSmall ? 8 : 12,
        runSpacing: isSmall ? 8 : 12,
        children: allSkills.map((skill) {
          final selected = selectedList.contains(skill);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              label: Text(
                skill,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: selected,
              onSelected: (_) => _toggleSkill(isTeachList ? selectedTeachSkills : selectedLearnSkills, skill),
              selectedColor: AppColors.primary.withOpacity(0.18),
              checkmarkColor: Colors.white,
              backgroundColor: AppColors.card,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: selected ? AppColors.primary : Colors.transparent),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        }).toList(),
      );
    });
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.9), width: 1.5),
      ),
      labelStyle: TextStyle(color: AppColors.text.withOpacity(0.9)),
    );
  }

  List<int> _createSkillsVector(List<String> selectedSkills) {
    return List<int>.generate(
      allSkills.length,
      (index) => selectedSkills.contains(allSkills[index]) ? 1 : 0,
    );
  }

  Future<void> _saveProfile() async {
    final phone = _phoneController.text.trim();
    if (!isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number (e.g., 03XXXXXXXXX or +923XXXXXXXXX)')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    List<String> teachSkills = [];
    List<String> learnSkills = [];
    if (selectedRole == 'Instructor' || selectedRole == 'Both') teachSkills = selectedTeachSkills;
    if (selectedRole == 'Student' || selectedRole == 'Both') learnSkills = selectedLearnSkills;
    final common = teachSkills.toSet().intersection(learnSkills.toSet());
    if (common.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skills to Teach and Learn cannot be the same')));
      return;
    }
    List<int> skillsToTeachVector = _createSkillsVector(teachSkills);
    List<int> skillsToLearnVector = _createSkillsVector(learnSkills);
    // Get userId from widget, or from SharedPreferences if null
    String? userId = widget.userId;
    if (userId == null) {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
    }
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No authenticated user found')));
      return;
    }
    final userData = {
      'Fullname': _fullname.text.trim(),
      'phone': phone,
      'gender': _gender,
      'role': selectedRole,
      'education': _educationController.text.trim(),
      'country': _countryController.text.trim(),
      'skillsToTeach': teachSkills,
      'skillsToTeachVector': skillsToTeachVector,
      'skillsToLearn': learnSkills,
      'skillsToLearnVector': skillsToLearnVector,
      'profileSet': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
    try {
      final success = await ApiService.updateProfile(userId, userData);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully'), backgroundColor: Colors.green));
        if (widget.cameFromProfilePage) {
          Navigator.pop(context);
        } else {
          if (selectedRole.toLowerCase() == 'student') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentHomePage()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(userId: userId!)));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    }
  }

  Widget _styledDropdown(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;
    final displayName = _fullname.text.isNotEmpty ? _fullname.text : 'User';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: widget.hideBackButton
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: const Text("Set Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? screenWidth * 0.15 : 20, vertical: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // TOP: gradient header banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.18), AppColors.primary.withOpacity(0.06)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.06)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.12),
                            ),
                            child: Icon(Icons.waving_hand_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome, $displayName",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                                ),
                                const SizedBox(height: 6),
                                Text("Let's set up your colorful profile so you can connect & learn!",
                                    style: TextStyle(fontSize: 13, color: AppColors.text.withOpacity(0.8))),
                              ],
                            ),
                          ),
                          // Small progress indicator (purely decorative)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text("Step", style: TextStyle(fontSize: 12, color: AppColors.text.withOpacity(0.7))),
                                Text("1/1", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FORM
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Two-column layout for wide screens
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Full name
                                      TextFormField(
                                        controller: _fullname,
                                        decoration: _inputDecoration('Full Name'),
                                        textInputAction: TextInputAction.next,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      // Phone
                                      TextFormField(
                                        controller: _phoneController,
                                        decoration: _inputDecoration('Phone Number', hint: '03XXXXXXXXX or +923XXXXXXXXX'),
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.next,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      // Gender
                                      _styledDropdown(
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _gender,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                                            ],
                                            onChanged: (val) => setState(() => _gender = val),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Education
                                      _styledDropdown(
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _educationController.text.isNotEmpty ? _educationController.text : null,
                                            isExpanded: true,
                                            hint: const Text('Select Education'),
                                            items: [
                                              'High School',
                                              'Intermediate',
                                              'Bachelor\'s',
                                              'Master\'s',
                                              'PhD',
                                              'Diploma',
                                              'Short Course',
                                            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                            onChanged: (val) => setState(() => _educationController.text = val ?? ''),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Right column
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Role
                                      _styledDropdown(
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedRole,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(value: 'Student', child: Text('Student')),
                                              DropdownMenuItem(value: 'Instructor', child: Text('Instructor')),
                                              DropdownMenuItem(value: 'Both', child: Text('Both')),
                                            ],
                                            onChanged: (val) => setState(() => selectedRole = val ?? 'Student'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Country
                                      _styledDropdown(
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _countryController.text.isNotEmpty ? _countryController.text : null,
                                            isExpanded: true,
                                            hint: const Text('Select Country'),
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
                                            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                            onChanged: (val) => setState(() => _countryController.text = val ?? ''),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Spacer for alignment
                                      const SizedBox(height: 56),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                          // single-column for mobile / narrow screens
                            Column(
                              children: [
                                TextFormField(
                                  controller: _fullname,
                                  decoration: _inputDecoration('Full Name'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: _inputDecoration('Phone Number', hint: '03XXXXXXXXX or +923XXXXXXXXX'),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null,
                                ),
                                const SizedBox(height: 12),
                                _styledDropdown(
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _gender,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      ],
                                      onChanged: (val) => setState(() => _gender = val),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _styledDropdown(
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedRole,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'Student', child: Text('Student')),
                                        DropdownMenuItem(value: 'Instructor', child: Text('Instructor')),
                                        DropdownMenuItem(value: 'Both', child: Text('Both')),
                                      ],
                                      onChanged: (val) => setState(() => selectedRole = val ?? 'Student'),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _styledDropdown(
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _educationController.text.isNotEmpty ? _educationController.text : null,
                                      isExpanded: true,
                                      hint: const Text('Select Education'),
                                      items: [
                                        'High School',
                                        'Intermediate',
                                        'Bachelor\'s',
                                        'Master\'s',
                                        'PhD',
                                        'Diploma',
                                        'Short Course',
                                      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                      onChanged: (val) => setState(() => _educationController.text = val ?? ''),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _styledDropdown(
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _countryController.text.isNotEmpty ? _countryController.text : null,
                                      isExpanded: true,
                                      hint: const Text('Select Country'),
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
                                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (val) => setState(() => _countryController.text = val ?? ''),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          // Skills to Learn (conditional)
                          if (selectedRole == 'Student' || selectedRole == 'Both') ...[
                            Row(
                              children: [
                                Icon(Icons.school_outlined, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text('Skills You Want to Learn',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildSkillChips(selectedLearnSkills, false),
                            const SizedBox(height: 20),
                          ],

                          // Skills to Teach (conditional)
                          if (selectedRole == 'Instructor' || selectedRole == 'Both') ...[
                            Row(
                              children: [
                                Icon(Icons.psychology_outlined, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text('Skills You Can Teach',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildSkillChips(selectedTeachSkills, true),
                            const SizedBox(height: 20),
                          ],

                          // Save button (centered)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveProfile,
                                icon: const Icon(Icons.save_rounded, size: 20, color: Colors.white),
                                label: const Text('Save', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

