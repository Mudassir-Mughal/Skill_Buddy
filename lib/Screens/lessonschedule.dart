import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class LessonSchedulePage extends StatefulWidget {
  final String currentUserId; // Instructor ID
  final String peerId; // Student ID

  // For editing
  final String? lessonId;
  final Map<String, dynamic>? lessonData;
  final bool isEdit;

  LessonSchedulePage({
    required this.currentUserId,
    required this.peerId,
    this.lessonId,
    this.lessonData,
    this.isEdit = false,
  });

  @override
  _LessonSchedulePageState createState() => _LessonSchedulePageState();
}

class _LessonSchedulePageState extends State<LessonSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _outlineController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedRepeat;

  final List<String> _durations = ["30 min", "1 hour", "2 hours"];
  final List<String> _repeatOptions = ["None", "1 day", "1 week", "1 month"];

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill fields
    if (widget.isEdit && widget.lessonData != null) {
      final data = widget.lessonData!;
      _outlineController.text = data['outline'] ?? '';
      // Parse date
      if (data['date'] != null && data['date'] is String) {
        final dateParts = (data['date'] as String).split("-");
        if (dateParts.length == 3) {
          _selectedDate = DateTime(
            int.tryParse(dateParts[0]) ?? DateTime.now().year,
            int.tryParse(dateParts[1]) ?? DateTime.now().month,
            int.tryParse(dateParts[2]) ?? DateTime.now().day,
          );
        }
      }
      // Parse time
      if (data['time'] != null && data['time'] is String) {
        final timeParts = (data['time'] as String).split(":");
        if (timeParts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? 0,
            minute: int.tryParse(timeParts[1]) ?? 0,
          );
        }
      }
      _selectedDuration = data['duration'];
      _selectedRepeat = data['repeat'];
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleOrUpdateLesson() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both date and time.")),
      );
      return;
    }

    if (widget.isEdit && widget.lessonId != null) {
      // Update existing lesson
      final lessonRef = FirebaseFirestore.instance.collection("lessons").doc(widget.lessonId);
      final lessonData = {
        "instructorId": widget.currentUserId,
        "studentId": widget.peerId,
        "outline": _outlineController.text.trim(),
        "date": "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        "time": "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
        "duration": _selectedDuration ?? "1 hour",
        "repeat": _selectedRepeat ?? "None",
        // Don't change status or createdAt here
      };
      await lessonRef.update(lessonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lesson Updated Successfully ✅")),
      );
      Navigator.pop(context);
    } else {
      // Schedule new lesson
      final lessonRef = FirebaseFirestore.instance.collection("lessons").doc();
      final lessonId = lessonRef.id;

      final lessonData = {
        "lessonId": lessonId,
        "instructorId": widget.currentUserId,
        "studentId": widget.peerId,
        "outline": _outlineController.text.trim(),
        "date": "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        "time": "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
        "duration": _selectedDuration ?? "1 hour",
        "repeat": _selectedRepeat ?? "None",
        "status": "scheduled",
        "createdAt": FieldValue.serverTimestamp(),
      };

      await lessonRef.set(lessonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lesson Scheduled Successfully ✅")),
      );

      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon, String? hint}) {
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
      hintText: hint,
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
          color: Colors.grey.withOpacity(0.08),
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
      appBar: AppBar(
        title: Text(
          widget.isEdit ? "Edit Lesson" : "Schedule Lesson",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColors.primary),
        elevation: 0.8,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.10),
                      AppColors.primary.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEdit
                            ? "Update lesson details and reschedule your class"
                            : "Schedule a new lesson for your student",
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
              // Lesson Outline
              Container(
                decoration: _getBoxDecoration(),
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _outlineController,
                  decoration: _inputDecoration('Lesson Outline', icon: Icons.menu_book_rounded),
                  validator: (val) => val == null || val.isEmpty ? "Enter lesson outline" : null,
                ),
              ),
              // Date Picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  decoration: _getBoxDecoration(),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        'Date',
                        icon: Icons.calendar_today_rounded,
                        hint: "Select date",
                      ),
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ""
                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      ),
                      validator: (_) => _selectedDate == null ? "Select date" : null,
                    ),
                  ),
                ),
              ),
              // Time Picker
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  decoration: _getBoxDecoration(),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        'Time',
                        icon: Icons.access_time_rounded,
                        hint: "Select time",
                      ),
                      controller: TextEditingController(
                        text: _selectedTime == null ? "" : _selectedTime!.format(context),
                      ),
                      validator: (_) => _selectedTime == null ? "Select time" : null,
                    ),
                  ),
                ),
              ),
              // Duration Dropdown
              Container(
                decoration: _getBoxDecoration(),
                margin: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Class Duration', icon: Icons.timer_rounded),
                  value: _selectedDuration,
                  items: _durations
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedDuration = val),
                  validator: (val) => val == null ? "Select duration" : null,
                ),
              ),
              // Repeat Dropdown
              Container(
                decoration: _getBoxDecoration(),
                margin: const EdgeInsets.only(bottom: 28),
                child: DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Repeat Class', icon: Icons.repeat_rounded),
                  value: _selectedRepeat,
                  items: _repeatOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedRepeat = val),
                  validator: (val) => val == null ? "Select repeat option" : null,
                ),
              ),
              // Save/Update Button
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
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _scheduleOrUpdateLesson,
                  label: Text(
                    widget.isEdit ? "Update Lesson" : "Schedule Lesson",
                    style: const TextStyle(
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