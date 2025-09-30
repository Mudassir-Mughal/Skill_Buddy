import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Myskills.dart';
import 'theme.dart';

class AddSkillPage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? skillId;

  const AddSkillPage({super.key, this.existingData, this.skillId});

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  final _formKey = GlobalKey<FormState>();
  String _expertlevel = 'Beginner';

  final _descriptionController = TextEditingController();
  final _totalClassesController = TextEditingController();
  final _durationController = TextEditingController();
  final _exchangeSkillController = TextEditingController();
  final _priceController = TextEditingController();

  // NEW: For skills dropdown
  List<String> _skillsToTeach = [];
  String? _selectedSkill;

  @override
  void initState() {
    super.initState();
    _fetchTeachSkills();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _selectedSkill = data['title'] ?? null;
      _descriptionController.text = data['description'] ?? '';
      _totalClassesController.text = data['totalClasses']?.toString() ?? '';
      _durationController.text = data['duration'] ?? '';
      _exchangeSkillController.text = (data['exchangeFor'] is List)
          ? (data['exchangeFor'] as List).join(', ')
          : (data['exchangeFor'] ?? '').toString();
      _priceController.text = data['price']?.toString() ?? '';
      _expertlevel = data['expertlevel'] ?? 'Beginner';
    }
  }

  Future<void> _fetchTeachSkills() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final skills = doc.data()?['skillsToTeach'] as List<dynamic>? ?? [];
    setState(() {
      _skillsToTeach = skills.map((e) => e.toString()).toList();
      if (_selectedSkill == null && _skillsToTeach.isNotEmpty) {
        _selectedSkill = _skillsToTeach.first;
      }
    });
  }

  Future<void> _saveSkill() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Prepare data
      final skillData = {
        'userId': user.uid,
        'instructor': user.displayName ?? '',
        'title': _selectedSkill ?? '',
        'description': _descriptionController.text.trim(),
        'expertlevel': _expertlevel,
        'totalClasses': int.tryParse(_totalClassesController.text.trim()) ?? 0,
        'duration': _durationController.text.trim(),
        'exchangeFor': _exchangeSkillController.text.trim().isEmpty
            ? []
            : _exchangeSkillController.text.trim().split(','),
        'price': int.tryParse(_priceController.text.trim()) ?? 0,
        'timestamp': Timestamp.now(),
      };

      if (widget.skillId != null) {
        // Update existing skill
        await FirebaseFirestore.instance
            .collection('skills')
            .doc(widget.skillId)
            .update(skillData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill updated successfully!')),
        );
      } else {
        // Add new skill
        await FirebaseFirestore.instance.collection('skills').add(skillData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill added successfully!')),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MySkillsPage()),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalClassesController.dispose();
    _durationController.dispose();
    _exchangeSkillController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      prefixIcon: icon != null
          ? Icon(
        icon,
        color: AppColors.primary.withOpacity(0.7),
        size: 22,
      )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      isDense: true,
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BoxDecoration _getBoxDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Share your expertise and connect with learners",
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              Text(
                "Basic Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Skill Title as Dropdown (UPDATED)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSkill,
                  items: _skillsToTeach.map((skill) {
                    return DropdownMenuItem(
                      value: skill,
                      child: Text(skill),
                    );
                  }).toList(),
                  decoration: _inputDecoration('Skill Title').copyWith(
                    prefixIcon: Icon(Icons.school_outlined, color: AppColors.primary),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please select a skill to teach' : null,
                  onChanged: (value) {
                    setState(() {
                      _selectedSkill = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Skill Description')
                      .copyWith(
                    prefixIcon: Icon(Icons.description_outlined, color: AppColors.primary),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Skill Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Expertise Level Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Icon(Icons.grade_outlined, color: AppColors.primary),
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _expertlevel,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          dropdownColor: Colors.white,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                            DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                            DropdownMenuItem(value: 'Expert', child: Text('Expert')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _expertlevel = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Total Classes
              Container(
                decoration: _getBoxDecoration(),
                child: TextFormField(
                  controller: _totalClassesController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Total Classes')
                      .copyWith(
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter total classes' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Duration
              Container(
                decoration: _getBoxDecoration(),
                child: TextFormField(
                  controller: _durationController,
                  decoration: _inputDecoration('Duration per Class')
                      .copyWith(
                    prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
                    hintText: 'e.g. 1 hour',
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter duration' : null,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Exchange & Pricing",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Exchange Skills
              Container(
                decoration: _getBoxDecoration(),
                child: TextFormField(
                  controller: _exchangeSkillController,
                  decoration: _inputDecoration('Skills to Exchange')
                      .copyWith(
                    prefixIcon: Icon(Icons.swap_horiz_outlined, color: AppColors.primary),
                    hintText: 'Comma separated skills',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price
              Container(
                decoration: _getBoxDecoration(),
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Price (PKR)')
                      .copyWith(
                    prefixIcon: Icon(Icons.attach_money_outlined, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _saveSkill,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text(
                    'Save Skill',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}