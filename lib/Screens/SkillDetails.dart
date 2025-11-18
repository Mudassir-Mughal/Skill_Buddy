import 'package:flutter/material.dart';
import '../Service/api_service.dart';
import 'instructorprofile.dart';
import 'theme.dart';
import '../config.dart';

class SkillDetailsPage extends StatefulWidget {
  final String skillId;

  const SkillDetailsPage({super.key, required this.skillId});

  @override
  State<SkillDetailsPage> createState() => _SkillDetailsPageState();
}

class _SkillDetailsPageState extends State<SkillDetailsPage> {
  late String currentUserId;
  bool isBookmarked = false;
  bool isRequestSent = false;
  bool isLoading = true;
  bool isOwner = false;

  Map<String, dynamic>? skill;
  String instructorName = '';
  String instructorId = '';

  @override
  void initState() {
    super.initState();

    // ✅ Replace this with your actual logged-in user ID
    currentUserId = ApiService.currentUserId ?? '';
    // Example: use from auth

    _loadSkillAndState();
  }

  Future<void> _loadSkillAndState() async {
    final skillData = await ApiService.getSkillById(widget.skillId);
    if (skillData == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        skill = null;
      });
      return;
    }

    instructorId = skillData['userId'] ?? '';
    isOwner = instructorId == currentUserId; // ✅ owner check

    final userData = await ApiService.getUserById(instructorId);
    instructorName = userData?['Fullname'] ?? 'Unknown';

    isBookmarked = await ApiService.isBookmarked(currentUserId, widget.skillId);

    isRequestSent = await ApiService.isRequestSent(currentUserId, widget.skillId);

    if (!mounted) return;
    setState(() {
      skill = skillData;
      isLoading = false;
    });
  }

  Future<void> _toggleBookmark() async {
    if (isBookmarked) {
      await ApiService.removeBookmark(currentUserId, widget.skillId);
      if (!mounted) return;
      setState(() => isBookmarked = false);
    } else {
      await ApiService.addBookmark(currentUserId, widget.skillId);
      if (!mounted) return;
      setState(() => isBookmarked = true);
    }
  }

  Future<void> _sendRequest() async {
    final success = await ApiService.sendRequest(
      skillId: widget.skillId,
      title: skill?['title'] ?? '',
      senderId: currentUserId,
      receiverId: instructorId,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        isRequestSent = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request. Please try again.')),
      );
    }
  }



  Widget _infoRow({required IconData icon, required String text, Color? iconColor, TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textStyle ?? const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSection({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((255 * 0.08).round()),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _requestStatus() {
    return Container(
      margin: const EdgeInsets.only(top: 30, bottom: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((255 * 0.10).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha((255 * 0.21).round())),
      ),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Text(
            "Request Sent",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (skill == null) {
      return const Scaffold(
        body: Center(child: Text('Skill not found.')),
      );
    }

    final int totalClasses = int.tryParse(skill?['totalClasses']?.toString() ?? '0') ?? 0;
    final int weeks = (totalClasses / 5).ceil();
    final String classDuration = skill?['duration'] ?? '30 mins';

    final showPrice = skill?['price'] != null &&
        skill!['price'].toString().trim().isNotEmpty &&
        skill?['price'] != 0;

    final List<dynamic> exchangeForList = (skill?['exchangeFor'] as List<dynamic>?) ?? [];
    final bool showExchangeFor = exchangeForList.isNotEmpty &&
        exchangeForList.any((e) => e.toString().trim().isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Skill Details', style: TextStyle(color: AppColors.buttonText)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.buttonText),
        elevation: 2,
        actions: [
          if (!isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: _toggleBookmark,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isBookmarked
                        ? Colors.redAccent.withAlpha((255 * 0.12).round())
                        : Colors.white.withAlpha((255 * 0.10).round()),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isBookmarked ? Icons.favorite : Icons.favorite_border,
                    color: isBookmarked ? Colors.redAccent : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill Title & Instructor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    skill?['title'] ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (showPrice)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((255 * 0.09).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Rs ${skill?['price']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InstructorProfilePage(
                      instructorId: instructorId,
                      baseUrl: baseUrl,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 19),
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    instructorName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),

            _cardSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill?['description'] ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.text,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _infoRow(
                    icon: Icons.access_time,
                    text: '$weeks week(s), $totalClasses classes',
                  ),
                  _infoRow(
                    icon: Icons.schedule,
                    text: 'Each class: $classDuration hour',
                  ),

                  if (showExchangeFor)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: List<Widget>.from(
                                exchangeForList
                                    .where((e) => e.toString().trim().isNotEmpty)
                                    .map(
                                      (e) => Chip(
                                    label: Text(
                                      e.toString(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primary.withAlpha((255 * 0.08).round()),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ✅ FINAL BUTTON LOGIC — EXACTLY AS YOU ASKED
            if (!isOwner)
              isRequestSent
                  ? _requestStatus()
                  : Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _sendRequest,
                    icon: const Icon(Icons.send, color: AppColors.buttonText, size: 22),
                    label: const Text(
                      'Send Request',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.buttonText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
