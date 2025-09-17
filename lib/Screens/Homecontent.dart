import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'SkillCard.dart';
import 'theme.dart';
import "SearchResult.dart";
import 'lessonschedule.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  String fullName = '';
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchUserFullName();
  }

  Future<void> fetchUserFullName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          fullName = doc.data()?['Fullname'] ?? 'User';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Fullname: $e");
      setState(() {
        fullName = 'User';
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

  Stream<List<QueryDocumentSnapshot>> fetchUpcomingLessons() async* {
    final instructorStream = FirebaseFirestore.instance
        .collection('lessons')
        .where('status', isEqualTo: 'scheduled')
        .where('instructorId', isEqualTo: currentUserId)
        .orderBy('date', descending: false)
        .snapshots();

    final studentStream = FirebaseFirestore.instance
        .collection('lessons')
        .where('status', isEqualTo: 'scheduled')
        .where('studentId', isEqualTo: currentUserId)
        .orderBy('date', descending: false)
        .snapshots();

    await for (final instructorSnap in instructorStream) {
      final studentSnap = await studentStream.first;
      final merged = [...instructorSnap.docs, ...studentSnap.docs];

      // Sort by date ascending
      merged.sort((a, b) {
        final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      yield merged;
    }
  }

  bool isLessonEditable(String date, String time) {
    try {
      final lessonDateTime =
      DateTime.parse("$date $time".trim().replaceAll('/', '-'));
      return lessonDateTime.isAfter(DateTime.now());
    } catch (e) {
      return true; // fallback: allow if parsing fails
    }
  }

  void _onEditLesson(BuildContext context, Map<String, dynamic> data, String lessonId) {
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
        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lessonId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Lesson deleted successfully"),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.background,
      child: SingleChildScrollView(
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
                  // Search Box
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
                  // Explore Banner
                  Container(
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
                  const SizedBox(height: 24),

                  // Popular Lessons Header


                  // Upcoming Lessons Section
                  Text(
                    "Upcoming Lessons",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upcoming Lessons Cards
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: fetchUpcomingLessons(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          alignment: Alignment.center,
                          child: Text(
                            "No upcoming lessons",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final lessons = snapshot.data!;

                      return Column(
                        children: lessons.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final lessonId = doc.id;
                          final outline = data['outline'] ?? '';
                          final date = data['date'] ?? '';
                          final time = data['time'] ?? '';
                          final duration = data['duration'] ?? '';
                          final instructorId = data['instructorId'];
                          final isInstructor = instructorId == currentUserId;
                          final canEditDelete = isInstructor && isLessonEditable(date, time);

                          // Improved Card UI
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.10),
                                  theme.colorScheme.secondary.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.07),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.secondary.withOpacity(0.3),
                                              theme.colorScheme.primary,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.school_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              outline,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.secondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    date,
                                                    style: theme.textTheme.bodyMedium,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.access_time, size: 16, color: theme.colorScheme.secondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    time,
                                                    style: theme.textTheme.bodyMedium,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.timer, size: 16, color: theme.colorScheme.secondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    duration,
                                                    style: theme.textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (canEditDelete)
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          color: theme.cardColor,
                                          elevation: 8,
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _onEditLesson(context, data, lessonId);
                                            } else if (value == 'delete') {
                                              _onDeleteLesson(context, lessonId);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primary.withOpacity(0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: const EdgeInsets.all(6),
                                                    child: Icon(Icons.edit_rounded, color: theme.colorScheme.primary, size: 20),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    "Edit",
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.primary,
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
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.error.withOpacity(0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding: const EdgeInsets.all(6),
                                                    child: Icon(Icons.delete_rounded, color: theme.colorScheme.error, size: 20),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "Delete",
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: theme.colorScheme.error,
                                                        ),
                                                      ),
                                                      Text(
                                                        "Cancel lesson",
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.error.withOpacity(0.7),
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
                                          child: Icon(Icons.lock_outline, color: Colors.grey[400]),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}