import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/similarity.dart';
import 'package:skill_buddy_fyp/Screens/videocall.dart';
import '../Models/MatchUser.dart';
import '../Service/MatchService.dart';
import '../Service/api_service.dart';
import '../Service/video_api.dart';
import 'SkillCard.dart';
import 'theme.dart';
import "SearchResult.dart";
import 'lessonschedule.dart';
import 'dart:async';
import '../config.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  String fullName = '';
  String currentUserName = '';
  String currentUserRole = '';
  List<String> currentUserSkillsToLearn = [];
  List<String> currentUserSkillsToTeach = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String currentUserId = ApiService.currentUserId ?? '';

  late Future<List<MatchUser>> _similarityMatchesFuture;

  // NEW: local lessons list and polling timer
  List<Map<String, dynamic>> _lessons = [];
  bool _lessonsLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    fetchUserFullNameAndSkills();
    _similarityMatchesFuture = fetchSimilarityMatches();

    // Start polling MongoDB-backed API for lessons every 3 seconds.
    // This replaces Firestore snapshot listeners with periodic polling to achieve real-time-like updates.
    _startLessonPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startLessonPolling() {
    // Immediately poll once, then schedule periodic polls.
    _pollLessons();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollLessons();
    });
  }

  // ROBUST FIX: Multiple parsing strategies
  DateTime? parseDateTime(String date, String time) {
    try {
      debugPrint("🔧 PARSING INPUT - Date: '$date', Time: '$time'");

      // Strategy 1: Direct parsing with seconds
      String normalizedTime = time;
      if (time.split(':').length == 2) {
        normalizedTime = '$time:00';
      }

      String attempt1 = '$date $normalizedTime';
      debugPrint("🔧 STRATEGY 1 - Attempting: '$attempt1'");
      DateTime? result1 = DateTime.tryParse(attempt1);
      if (result1 != null) {
        debugPrint("🔧 STRATEGY 1 - SUCCESS: $result1");
        return result1;
      }

      // Strategy 2: Manual parsing
      try {
        debugPrint("🔧 STRATEGY 2 - Manual parsing");
        final dateParts = date.split('-');
        final timeParts = time.split(':');

        if (dateParts.length == 3 && timeParts.length >= 2) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

          final result2 = DateTime(year, month, day, hour, minute, second);
          debugPrint("🔧 STRATEGY 2 - SUCCESS: $result2");
          return result2;
        }
      } catch (e2) {
        debugPrint("🔧 STRATEGY 2 - FAILED: $e2");
      }

      // Strategy 3: UTC explicit parsing
      try {
        debugPrint("🔧 STRATEGY 3 - UTC parsing");
        String attempt3 = '${date}T$normalizedTime.000Z';
        debugPrint("🔧 STRATEGY 3 - Attempting: '$attempt3'");
        DateTime? result3 = DateTime.tryParse(attempt3);
        if (result3 != null) {
          debugPrint("🔧 STRATEGY 3 - SUCCESS: $result3");
          return result3.toLocal(); // Convert to local time
        }
      } catch (e3) {
        debugPrint("🔧 STRATEGY 3 - FAILED: $e3");
      }

      // Strategy 4: Alternative formats
      try {
        debugPrint("🔧 STRATEGY 4 - Alternative formats");
        List<String> formats = [
          '$date $normalizedTime',
          '${date}T$normalizedTime',
          '${date}T${normalizedTime}Z',
          '$date $time',
        ];

        for (String format in formats) {
          debugPrint("🔧 STRATEGY 4 - Trying: '$format'");
          DateTime? result = DateTime.tryParse(format);
          if (result != null) {
            debugPrint("🔧 STRATEGY 4 - SUCCESS: $result");
            return result;
          }
        }
      } catch (e4) {
        debugPrint("🔧 STRATEGY 4 - FAILED: $e4");
      }

      debugPrint("🔧 ALL STRATEGIES FAILED");
      return null;
    } catch (e) {
      debugPrint("🔧 PARSING ERROR: $e");
      return null;
    }
  }

  Future<void> _pollLessons() async {
    try {
      final lessons = await ApiService.getLessonsForUser(instructorId: currentUserId, studentId: currentUserId);
      final scheduled = lessons.where((l) => l['status'] == 'scheduled').toList();

      final now = DateTime.now();

      // DEBUG: Print current time
      debugPrint("🕐 POLL DEBUG - Current time: $now");
      debugPrint("🕐 POLL DEBUG - Current time UTC: ${now.toUtc()}");

      // For each scheduled lesson, compute desired enabled state based on times and perform DB updates if needed.
      for (var data in scheduled) {
        final lessonId = data['_id'] ?? data['lessonId'] ?? '';
        final date = data['date'] ?? '';
        final startTimeRaw = data['start_time'] ?? '';
        final endTimeRaw = data['end_time'] ?? '';
        final enabled = data['enabled'] == true;

        // DEBUG: Print lesson data
        debugPrint("📚 LESSON DEBUG - ID: $lessonId");
        debugPrint("📚 LESSON DEBUG - Date: '$date'");
        debugPrint("📚 LESSON DEBUG - Start Time Raw: '$startTimeRaw'");
        debugPrint("📚 LESSON DEBUG - End Time Raw: '$endTimeRaw'");
        debugPrint("📚 LESSON DEBUG - Currently Enabled: $enabled");

        // ROBUST: Use new parsing function
        final lessonStart = parseDateTime(date, startTimeRaw);
        final lessonEnd = parseDateTime(date, endTimeRaw);

        debugPrint("✅ PARSED - Start: $lessonStart");
        debugPrint("✅ PARSED - End: $lessonEnd");

        // RULES:
        // 1) Button ENABLED when current time >= startTime
        // 2) Button DISABLED when current time > endTime
        // -> Therefore enabled if now >= start && now <= end (inclusive of endpoints).
        bool shouldBeEnabled = false;
        if (lessonStart != null && lessonEnd != null) {
          final startComparison = now.compareTo(lessonStart);
          final endComparison = now.compareTo(lessonEnd);

          debugPrint("⚖️ COMPARISON - now vs start: $startComparison (>=0 means now is after start)");
          debugPrint("⚖️ COMPARISON - now vs end: $endComparison (<=0 means now is before end)");

          shouldBeEnabled = (startComparison >= 0) && (endComparison <= 0);

          debugPrint("🎯 SHOULD BE ENABLED: $shouldBeEnabled");

          // If lesson is past endTime, mark completed and ensure disabled.
          if (endComparison > 0 && data['status'] == 'scheduled') {
            debugPrint("🏁 LESSON ENDED - Marking as completed");
            // mark completed and disable
            if (lessonId.isNotEmpty) {
              try {
                await ApiService.updateLesson(lessonId, {'status': 'completed', 'enabled': false});
                debugPrint("✅ UPDATED - Lesson marked as completed");
              } catch (e) {
                debugPrint("❌ UPDATE ERROR - completing lesson $lessonId: $e");
              }
            }
            // continue; already updated DB to completed
            continue;
          }
        } else if (lessonStart != null && lessonEnd == null) {
          // If no end time provided, enable when now >= start
          final startComparison = now.compareTo(lessonStart);
          shouldBeEnabled = startComparison >= 0;
          debugPrint("🎯 SHOULD BE ENABLED (no end time): $shouldBeEnabled");
        } else {
          // FALLBACK: If parsing completely fails, try simple comparison
          debugPrint("⚠️ PARSING FAILED - Attempting fallback comparison");
          try {
            final nowHour = now.hour;
            final nowMinute = now.minute;
            final startParts = startTimeRaw.split(':');
            if (startParts.length >= 2) {
              final startHour = int.parse(startParts[0]);
              final startMinute = int.parse(startParts[1]);
              final nowTotalMinutes = nowHour * 60 + nowMinute;
              final startTotalMinutes = startHour * 60 + startMinute;

              // Simple check: if we're past start time today
              if (date == '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}') {
                shouldBeEnabled = nowTotalMinutes >= startTotalMinutes;
                debugPrint("🔄 FALLBACK - Today match, should enable: $shouldBeEnabled (now: $nowTotalMinutes vs start: $startTotalMinutes)");
              } else {
                shouldBeEnabled = enabled; // Keep current state
                debugPrint("🔄 FALLBACK - Not today, keeping state: $shouldBeEnabled");
              }
            }
          } catch (fallbackError) {
            debugPrint("❌ FALLBACK FAILED: $fallbackError");
            shouldBeEnabled = enabled; // Keep current state
          }
        }

        if (lessonId.isNotEmpty && enabled != shouldBeEnabled) {
          debugPrint("🔄 UPDATING - Lesson $lessonId enabled: $enabled -> $shouldBeEnabled");
          try {
            await ApiService.updateLesson(lessonId, {'enabled': shouldBeEnabled});
            debugPrint("✅ UPDATED - Lesson enabled state changed successfully");
            // Update local data immediately to reflect the change
            data['enabled'] = shouldBeEnabled;
          } catch (e) {
            debugPrint("❌ UPDATE ERROR - enabling/disabling lesson $lessonId: $e");
          }
        } else {
          debugPrint("➡️ NO UPDATE NEEDED - enabled: $enabled, shouldBe: $shouldBeEnabled");
        }

        debugPrint("─────────────────────────────────────");
      }

      if (mounted) {
        setState(() {
          _lessons = scheduled;
          _lessonsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ POLLING ERROR: $e");
      if (mounted) {
        setState(() {
          // keep existing lessons shown if a poll fails
          _lessonsLoading = false;
        });
      }
    }
  }

  Future<void> fetchUserFullNameAndSkills() async {
    try {
      final user = await ApiService.getUserProfile(currentUserId);
      setState(() {
        fullName = user?['Fullname'] ?? 'User';
        currentUserName = user?['Fullname'] ?? 'User';
        currentUserRole = user?['role'] ?? '';
        currentUserSkillsToLearn = List<String>.from(user?['skillsToLearn'] ?? []);
        currentUserSkillsToTeach = List<String>.from(user?['skillsToTeach'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching Fullname or skills: $e");
      setState(() {
        fullName = 'User';
        currentUserName = 'User';
        currentUserRole = '';
        currentUserSkillsToLearn = [];
        currentUserSkillsToTeach = [];
        isLoading = false;
      });
    }
  }

  void _goToSearchResults(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsPage(initialQuery: trimmedValue),
        ),
      );
    }
  }

  Future<List<MatchUser>> fetchSimilarityMatches() async {
    final String currentUserId = ApiService.currentUserId ?? '';
    final List<Map<String, dynamic>> rawMatches = await MatchService(
      baseUrl: baseUrl,
      currentUserId: currentUserId,
    ).findMatches();
    List<MatchUser> matches = [];
    for (var m in rawMatches) {
      if ((m['similarity'] ?? 0.0) <= 0.0) continue;
      final user = await ApiService.getUserProfile(m['uid']);
      final skillsToTeach = List<String>.from(user?['skillsToTeach'] ?? []);
      final skillsToLearn = List<String>.from(user?['skillsToLearn'] ?? []);
      matches.add(MatchUser(
        uid: m['uid'],
        name: m['name'],
        similarity: m['similarity'],
        skillsToTeach: skillsToTeach,
        skillsToLearn: skillsToLearn,
      ));
    }
    return matches;
  }

  Future<List<Map<String, dynamic>>> fetchLessons() async {
    final lessons = await ApiService.getLessonsForUser(instructorId: currentUserId, studentId: currentUserId);
    return lessons.where((l) => l['status'] == 'scheduled').toList();
  }

  bool isLessonEditable(String date, String time) {
    try {
      final lessonDateTime = parseDateTime(date, time);
      return lessonDateTime?.isAfter(DateTime.now()) ?? true;
    } catch (e) {
      return true;
    }
  }

  void _onEditLesson(
      BuildContext context, Map<String, dynamic> data, String lessonId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonSchedulePage(
          currentUserId: currentUserId,
          peerId: data['studentId'],
          lessonId: lessonId,
          lessonData: data,
          isEdit: true,
        ),
      ),
    );
  }

  Future<void> _onDeleteLesson(BuildContext context, String lessonId) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.dialogBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_rounded,
                  size: 44, color: theme.colorScheme.error),
              const SizedBox(height: 18),
              Text(
                "Delete Lesson?",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to delete this lesson?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      try {
        final deleted = await ApiService.deleteLesson(lessonId);
        if (deleted) {
          if (context.mounted) {
            setState(() {}); // Refresh UI
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Lesson deleted successfully"),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Delete failed: Lesson not found or server error."),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Delete failed: $e"),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }

  bool isLessonOver(String date, String endTime) {
    try {
      final end = parseDateTime(date, endTime);
      return end?.isBefore(DateTime.now()) ?? false;
    } catch (e) {
      return false;
    }
  }

  String getPeerId(Map<String, dynamic> data) {
    if (data['instructorId'] == currentUserId) {
      return data['studentId'];
    } else {
      return data['instructorId'];
    }
  }

  // NOTE: checkAndEnableLesson left for compatibility, but polling handles enabling/disabling now.
  Future<void> checkAndEnableLesson(Map<String, dynamic> data, String lessonId) async {
    final enabled = data['enabled'] == true;
    final date = data['date'] ?? '';
    final startTimeRaw = data['start_time'] ?? '';
    if (!enabled && date != '' && startTimeRaw != '') {
      try {
        final start = parseDateTime(date, startTimeRaw);
        if (start != null && (DateTime.now().isAfter(start) || DateTime.now().isAtSameMomentAs(start))) {
          await ApiService.updateLesson(lessonId, {'enabled': true});
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Local copy of lessons for use in UI. Use the polled list (_lessons).
    final lessons = _lessonsLoading ? [] : _lessons;

    String formatTime(String time) {
      try {
        final parts = time.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final t = TimeOfDay(hour: hour, minute: minute);
          return t.format(context);
        }
      } catch (_) {}
      return time;
    }

    lessons.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '');
      final bDate = DateTime.tryParse(b['date'] ?? '');
      return (aDate ?? DateTime.now())
          .compareTo(bDate ?? DateTime.now());
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, $fullName",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Find your lessons today!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      onSubmitted: _goToSearchResults,
                      decoration: InputDecoration(
                        hintText: 'Search skills...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _goToSearchResults(_searchController.text);
                          },
                          child: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Discover Top Picks Card with Navigation Added ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchResultsPage(
                            initialQuery: "",
                            showSearchField: false,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "+100 lessons",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Discover Top Picks",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Explore our most popular skills",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- End Discover Top Picks Card ---

                  const SizedBox(height: 24),
                  Text(
                    "Upcoming Lessons",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_lessonsLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    )
                  else if (lessons.isEmpty)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 32),
                      alignment: Alignment.center,
                      child: Text(
                        "No upcoming lessons",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: lessons.map((data) {
                        final lessonId = data['_id'] ?? data['lessonId'] ?? '';
                        final outline = data['outline'] ?? '';
                        final date = data['date'] ?? '';
                        final startTimeRaw = data['start_time'] ?? '';
                        final endTimeRaw = data['end_time'] ?? '';
                        final instructorId = data['instructorId'];
                        final isInstructor = instructorId == currentUserId;
                        final canEditDelete = isInstructor && isLessonEditable(date, startTimeRaw);
                        final startTimePretty = formatTime(startTimeRaw);
                        final endTimePretty = formatTime(endTimeRaw);
                        final timeRange = (startTimePretty.isNotEmpty && endTimePretty.isNotEmpty)
                            ? "$startTimePretty - $endTimePretty"
                            : (startTimePretty.isNotEmpty ? startTimePretty : endTimePretty);
                        final lessonOver = isLessonOver(date, endTimeRaw);
                        final peerId = getPeerId(data);
                        final enabled = data['enabled'] == true;

                        // NOTE: enabling/disabling is handled by polling (_pollLessons).
                        // We keep UI behavior and button names unchanged.

                        return Container(
                          margin:
                          const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary
                                    .withOpacity(0.10),
                                theme.colorScheme.secondary
                                    .withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                            BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.07),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius:
                            BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(18),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme
                                                .secondary
                                                .withOpacity(
                                                0.3),
                                            theme.colorScheme
                                                .primary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end:
                                          Alignment.bottomRight,
                                        ),
                                      ),
                                      padding:
                                      const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.school_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            outline,
                                            style: theme
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                              fontWeight:
                                              FontWeight.w200,
                                              color: theme
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow
                                                .ellipsis,
                                          ),
                                          const SizedBox(
                                              height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                  Icons
                                                      .calendar_today,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme
                                                      .secondary),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                date,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                  Icons
                                                      .access_time,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme
                                                      .secondary),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                timeRange,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                    fontWeight:
                                                    FontWeight
                                                        .w600),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 10),
                                          if (lessonOver)
                                            SizedBox(
                                              width:
                                              double.infinity,
                                              child:
                                              ElevatedButton
                                                  .icon(
                                                icon: Icon(
                                                    Icons.delete,
                                                    color: Colors
                                                        .white),
                                                label: Text(
                                                  "Delete",
                                                  style:
                                                  TextStyle(
                                                    color: Colors
                                                        .white,
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                  ),
                                                ),
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                  Colors.red,
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        30),
                                                  ),
                                                  padding: EdgeInsets
                                                      .symmetric(
                                                      vertical:
                                                      10),
                                                ),
                                                onPressed:
                                                    () async {
                                                  await _onDeleteLesson(
                                                      context,
                                                      lessonId);
                                                },
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              width:
                                              double.infinity,
                                              child:
                                              ElevatedButton
                                                  .icon(
                                                icon: Icon(
                                                  Icons
                                                      .video_call_rounded,
                                                  color: enabled
                                                      ? Colors
                                                      .white
                                                      : Colors
                                                      .grey
                                                      .shade400,
                                                ),
                                                label: Text(
                                                  enabled
                                                      ? "Join Call"
                                                      : "Not Active",
                                                  style: TextStyle(
                                                    color: enabled
                                                        ? Colors
                                                        .white
                                                        : Colors
                                                        .grey
                                                        .shade400,
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                  ),
                                                ),
                                                onPressed: enabled
                                                    ? () async {
                                                  final lessonData = await ApiService.getLessonById(lessonId);
                                                  final roomId = lessonData?['roomId'];
                                                  if (roomId == null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text("Room ID not found for this lesson.")),
                                                    );
                                                    return;
                                                  }
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => MeetingScreen(
                                                        meetingId: roomId,
                                                        token: token,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                    : null,
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                  enabled
                                                      ? theme
                                                      .colorScheme
                                                      .primary
                                                      : Colors
                                                      .grey
                                                      .shade200,
                                                  shadowColor: enabled
                                                      ? theme.colorScheme.primary.withOpacity(0.18)
                                                      : Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  elevation: enabled ? 3 : 0,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (canEditDelete)
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color: theme
                                              .colorScheme
                                              .secondary,
                                        ),
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(
                                              18),
                                        ),
                                        color: theme.cardColor,
                                        elevation: 8,
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _onEditLesson(context,
                                                data, lessonId);
                                          } else if (value ==
                                              'delete') {
                                            _onDeleteLesson(
                                                context,
                                                lessonId);
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration:
                                                  BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(
                                                        0.12),
                                                    shape: BoxShape
                                                        .circle,
                                                  ),
                                                  padding:
                                                  const EdgeInsets
                                                      .all(
                                                      6),
                                                  child: Icon(
                                                      Icons
                                                          .edit_rounded,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      size: 20),
                                                ),
                                                const SizedBox(
                                                    width: 16),
                                                Text(
                                                  "Edit",
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                    FontWeight
                                                        .w600,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration:
                                                  BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .error
                                                        .withOpacity(
                                                        0.12),
                                                    shape: BoxShape
                                                        .circle,
                                                  ),
                                                  padding:
                                                  const EdgeInsets
                                                      .all(
                                                      6),
                                                  child: Icon(
                                                      Icons
                                                          .delete_rounded,
                                                      color: theme
                                                          .colorScheme
                                                          .error,
                                                      size: 20),
                                                ),
                                                const SizedBox(
                                                    width: 16),
                                                Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Text(
                                                      "Delete",
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                        FontWeight
                                                            .w600,
                                                        color: theme
                                                            .colorScheme
                                                            .error,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Cancel lesson",
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .error
                                                            .withOpacity(
                                                            0.7),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Tooltip(
                                        message: isInstructor
                                            ? "Lesson time has passed"
                                            : "View only",
                                        child: Icon(
                                            Icons.lock_outline,
                                            color:
                                            Colors.grey[400]),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),);
                      }).toList(),
                    ),
                  // --- SIMILARITY SECTION MOVED TO COMPONENT ---
                  SimilaritySection(
                    currentUserRole: currentUserRole,
                    currentUserSkillsToLearn: currentUserSkillsToLearn,
                    currentUserSkillsToTeach: currentUserSkillsToTeach,
                    similarityMatchesFuture: _similarityMatchesFuture,
                  ),
                  // --- END SIMILARITY SECTION ---
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

