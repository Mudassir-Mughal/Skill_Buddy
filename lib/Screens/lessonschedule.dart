import 'package:flutter/material.dart';
import 'theme.dart';
import '../Service/video_api.dart'; // <-- Import your createMeeting() and token
import '../Service/api_service.dart'; // <-- Add this import for API calls

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
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill fields
    if (widget.isEdit && widget.lessonData != null) {
      final data = widget.lessonData!;
      _outlineController.text = data['outline'] ?? '';

      // FIXED: Better date parsing
      if (data['date'] != null && data['date'] is String) {
        try {
          final dateStr = data['date'] as String;
          if (dateStr.contains('-')) {
            final dateParts = dateStr.split("-");
            if (dateParts.length == 3) {
              _selectedDate = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
            }
          }
        } catch (e) {
          debugPrint("Error parsing date: $e");
        }
      }

      // FIXED: Better time parsing
      if (data['start_time'] != null && data['start_time'] is String) {
        try {
          final timeStr = data['start_time'] as String;
          final timeParts = timeStr.split(":");
          if (timeParts.length >= 2) {
            _selectedStartTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        } catch (e) {
          debugPrint("Error parsing start time: $e");
        }
      }

      // FIXED: Better time parsing
      if (data['end_time'] != null && data['end_time'] is String) {
        try {
          final timeStr = data['end_time'] as String;
          final timeParts = timeStr.split(":");
          if (timeParts.length >= 2) {
            _selectedEndTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        } catch (e) {
          debugPrint("Error parsing end time: $e");
        }
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedStartTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  String? _validateTimes() {
    if (_selectedStartTime == null || _selectedEndTime == null) return null;
    final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    if (endMinutes <= startMinutes) {
      return "End time must be after start time";
    }
    return null;
  }

  // FIXED: Better date/time validation
  String? _validateDateTime() {
    if (_selectedDate == null) return "Please select a date";
    if (_selectedStartTime == null) return "Please select start time";
    if (_selectedEndTime == null) return "Please select end time";

    final now = DateTime.now();
    final lessonDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    // Check if lesson is in the past
    if (lessonDateTime.isBefore(now)) {
      return "Cannot schedule lessons in the past";
    }

    return _validateTimes();
  }

  Future<void> _scheduleOrUpdateLesson() async {
    if (!_formKey.currentState!.validate()) return;

    // FIXED: Better validation
    final dateTimeValidation = _validateDateTime();
    if (dateTimeValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateTimeValidation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );

    try {
      // FIXED: Consistent date formatting (YYYY-MM-DD)
      final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final startTimeStr = "${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}";
      final endTimeStr = "${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}";

      // FIXED: Determine initial enabled state based on current time
      final now = DateTime.now();
      final lessonStart = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      final lessonEnd = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );

      // Check if lesson should be enabled immediately
      final shouldBeEnabled = now.isAfter(lessonStart) && now.isBefore(lessonEnd);

      final lessonData = {
        "instructorId": widget.currentUserId,
        "studentId": widget.peerId,
        "outline": _outlineController.text.trim(),
        "date": dateStr,
        "start_time": startTimeStr,
        "end_time": endTimeStr,
        "enabled": shouldBeEnabled, // FIXED: Set based on current time
        "status": "scheduled", // FIXED: Always set status
      };

      debugPrint("📝 LESSON DATA:");
      debugPrint("   Date: $dateStr");
      debugPrint("   Start: $startTimeStr");
      debugPrint("   End: $endTimeStr");
      debugPrint("   Should be enabled: $shouldBeEnabled");
      debugPrint("   Lesson start time: $lessonStart");
      debugPrint("   Current time: $now");

      if (widget.isEdit && widget.lessonId != null) {
        // FIXED: For edits, preserve roomId if it exists
        if (widget.lessonData != null && widget.lessonData!['roomId'] != null) {
          lessonData['roomId'] = widget.lessonData!['roomId'];
        }

        // Update lesson in MongoDB
        final updated = await ApiService.updateLesson(widget.lessonId!, lessonData);
        Navigator.pop(context); // Close loading dialog

        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lesson Updated Successfully ✅"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update lesson"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // FIXED: Create meeting and handle errors properly
        String? roomId;
        try {
          roomId = await createMeeting(); // VideoSDK API call
          debugPrint("📹 Created VideoSDK room: $roomId");
        } catch (e) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to create video room: $e"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (roomId != null) {
          lessonData['roomId'] = roomId;

          final created = await ApiService.createLesson(lessonData);
          Navigator.pop(context); // Close loading dialog

          if (created != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Lesson Scheduled Successfully ✅"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to schedule lesson"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to create video room"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error scheduling lesson: $e");
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
        color: AppColors.primary.withOpacity(0.9),
        size: 22,
      )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.08),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2.2,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(18),
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
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      isDense: true,
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.09),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  BoxDecoration _getBoxDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 6),
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
        elevation: 1.1,
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
                      AppColors.primary.withOpacity(0.07),
                      AppColors.primary.withOpacity(0.015),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
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
                      style: TextStyle(
                        color: _selectedDate == null ? Colors.grey[500] : AppColors.primary,
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                      validator: (_) => _selectedDate == null ? "Select date" : null,
                    ),
                  ),
                ),
              ),
              // Start Time Picker
              GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  decoration: _getBoxDecoration(),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        'Start Time',
                        icon: Icons.access_time_rounded,
                        hint: "Select start time",
                      ),
                      controller: TextEditingController(
                        text: _selectedStartTime == null ? "" : _selectedStartTime!.format(context),
                      ),
                      style: TextStyle(
                        color: _selectedStartTime == null ? Colors.grey[500] : AppColors.primary,
                        fontWeight: _selectedStartTime == null ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                      validator: (_) => _selectedStartTime == null ? "Select start time" : null,
                    ),
                  ),
                ),
              ),
              // End Time Picker
              GestureDetector(
                onTap: _pickEndTime,
                child: Container(
                  decoration: _getBoxDecoration(),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _inputDecoration(
                        'End Time',
                        icon: Icons.access_time_filled_rounded,
                        hint: "Select end time",
                      ),
                      controller: TextEditingController(
                        text: _selectedEndTime == null ? "" : _selectedEndTime!.format(context),
                      ),
                      style: TextStyle(
                        color: _selectedEndTime == null ? Colors.grey[500] : AppColors.primary,
                        fontWeight: _selectedEndTime == null ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                      validator: (_) => _selectedEndTime == null ? "Select end time" : _validateTimes(),
                    ),
                  ),
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
                      color: AppColors.primary.withOpacity(0.15),
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
                  icon: Icon(Icons.save, color: Colors.white),
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