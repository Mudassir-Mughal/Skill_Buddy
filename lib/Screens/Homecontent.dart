import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/similarity.dart';
import 'package:skill_buddy_fyp/Screens/videocall.dart';
import '../Models/MatchUser.dart';
import '../Service/MatchService.dart';
import '../Service/video_api.dart';
import 'SkillCard.dart';
import 'theme.dart';
import "SearchResult.dart";
import 'lessonschedule.dart';
// <-- Import the new component

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

// MatchUser class is now only in SimilaritySection.dart

class _HomeScreenContentState extends State<HomeScreenContent> {
  String fullName = '';
  String currentUserName = '';
  String currentUserRole = '';
  List<String> currentUserSkillsToLearn = [];
  List<String> currentUserSkillsToTeach = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late Future<List<MatchUser>> _similarityMatchesFuture;

  @override
  void initState() {
    super.initState();
    fetchUserFullNameAndSkills();
    _similarityMatchesFuture = fetchSimilarityMatches();
  }

  Future<void> fetchUserFullNameAndSkills() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();
        setState(() {
          fullName = data?['Fullname'] ?? 'User';
          currentUserName = data?['Fullname'] ?? 'User';
          currentUserRole = data?['role'] ?? '';
          currentUserSkillsToLearn = List<String>.from(data?['skillsToLearn'] ?? []);
          currentUserSkillsToTeach = List<String>.from(data?['skillsToTeach'] ?? []);
          isLoading = false;
        });
      }
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
    final List<Map<String, dynamic>> rawMatches = await MatchService().findMatches();

    List<MatchUser> matches = [];
    for (var m in rawMatches) {
      if ((m['similarity'] ?? 0.0) <= 0.0) continue; // filter out zero similarity
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(m['uid']).get();
      final data = userDoc.data();
      final skillsToTeach = List<String>.from(data?['skillsToTeach'] ?? []);
      final skillsToLearn = List<String>.from(data?['skillsToLearn'] ?? []);

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

  Stream<List<QueryDocumentSnapshot>> fetchLessonsRealtime() {
    return FirebaseFirestore.instance
        .collection('lessons')
        .where('status', isEqualTo: 'scheduled')
        .where(Filter.or(
      Filter('studentId', isEqualTo: currentUserId),
      Filter('instructorId', isEqualTo: currentUserId),
    ))
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  bool isLessonEditable(String date, String time) {
    try {
      final lessonDateTime =
      DateTime.parse("$date $time".trim().replaceAll('/', '-'));
      return lessonDateTime.isAfter(DateTime.now());
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

  bool isLessonOver(String date, String endTime) {
    try {
      final end = DateTime.parse("$date $endTime".replaceAll('/', '-'));
      return DateTime.now().isAfter(end);
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

  Future<void> checkAndEnableLesson(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final enabled = data['enabled'] == true;
    final date = data['date'] ?? '';
    final startTimeRaw = data['start_time'] ?? '';

    if (!enabled && date != '' && startTimeRaw != '') {
      try {
        final start = DateTime.parse("$date $startTimeRaw".replaceAll('/', '-'));
        if (DateTime.now().isAfter(start) ||
            DateTime.now().isAtSameMomentAs(start)) {
          await doc.reference.update({'enabled': true});
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: fetchLessonsRealtime(),
        builder: (context, snapshot) {
          final lessons = snapshot.data ?? [];

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

          return SingleChildScrollView(
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
                              color:
                              theme.colorScheme.primary.withOpacity(0.3),
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
                                      color:
                                      Colors.white.withOpacity(0.9),
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
                      Text(
                        "Upcoming Lessons",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (lessons.isEmpty)
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
                          children: lessons.map((doc) {
                            final data =
                            doc.data() as Map<String, dynamic>;
                            final lessonId = doc.id;
                            final outline = data['outline'] ?? '';
                            final date = data['date'] ?? '';
                            final startTimeRaw = data['start_time'] ?? '';
                            final endTimeRaw = data['end_time'] ?? '';
                            final instructorId = data['instructorId'];
                            final isInstructor =
                                instructorId == currentUserId;
                            final canEditDelete = isInstructor &&
                                isLessonEditable(date, startTimeRaw);

                            final startTimePretty =
                            formatTime(startTimeRaw);
                            final endTimePretty =
                            formatTime(endTimeRaw);
                            final timeRange = (startTimePretty.isNotEmpty &&
                                endTimePretty.isNotEmpty)
                                ? "$startTimePretty - $endTimePretty"
                                : (startTimePretty.isNotEmpty
                                ? startTimePretty
                                : endTimePretty);

                            final lessonOver =
                            isLessonOver(date, endTimeRaw);
                            final peerId = getPeerId(data);

                            final enabled = data['enabled'] == true;

                            checkAndEnableLesson(doc);

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
                                                    onPressed:
                                                    enabled
                                                        ? () async {
                                                      final lessonSnap = await FirebaseFirestore.instance
                                                          .collection('lessons')
                                                          .doc(lessonId)
                                                          .get();
                                                      final lessonData = lessonSnap.data();
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
                              ),
                            );
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
          );
        },
      ),
    );
  }
}