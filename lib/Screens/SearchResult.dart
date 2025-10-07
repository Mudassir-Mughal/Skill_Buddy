import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SkillCard.dart';
import 'SkillDetails.dart';
import 'theme.dart';
import 'dart:async';
import '../Service/skilllist.dart'; // <-- Import shared skills and index

class SearchResultsPage extends StatefulWidget {
  final String initialQuery;
  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _allSkills = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(text: widget.initialQuery);
    _searchController.addListener(_onSearchChanged);
    _fetchAllSkills().then((_) {
      if (widget.initialQuery.isNotEmpty) {
        _filterSkills(widget.initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllSkills() async {
    setState(() => _isLoading = true);

    try {
      // Batch fetch all users
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final userMap = {
        for (var doc in userSnapshot.docs)
          doc.id: (doc.data()['Fullname'] ?? 'Unknown')
      };

      // Fetch all skills
      final skillSnapshot = await FirebaseFirestore.instance.collection('skills').get();
      List<Map<String, dynamic>> allSkillsList = skillSnapshot.docs.map((doc) {
        final data = doc.data();
        final userId = data['userId'];
        final instructorName = userMap[userId] ?? 'Unknown';

        final dynamic price = data['price'];
        final List<dynamic> exchangeForRaw = data['exchangeFor'] ?? [];
        final List<String> exchangeForList = exchangeForRaw
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .toList();

        final bool isPriceEmpty = price == null || (price is num && price <= 0);
        final bool isExchangeForEmpty = exchangeForList.isEmpty;

        // If both are empty, skip
        if (isPriceEmpty && isExchangeForEmpty) {
          return null; // skip this skill
        }

        return {
          'skillId': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'totalClasses': data['totalClasses'] ?? 0,
          'duration': data['duration'] ?? '',
          'price': isPriceEmpty ? null : price,
          'exchangeFor': isExchangeForEmpty ? null : exchangeForList,
          'instructor': instructorName,
        };
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

      setState(() {
        _allSkills = allSkillsList;
        _results = allSkillsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error during fetch: $e');
      setState(() {
        _allSkills = [];
        _results = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    // Debounce to avoid filtering on every keystroke instantly
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final query = _searchController.text.trim();
      _filterSkills(query);
    });
  }

  void _filterSkills(String query) async {
    List<Map<String, dynamic>> filtered;
    if (query.isEmpty) {
      filtered = _allSkills;
    } else {
      filtered = _allSkills.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      _results = filtered;
    });
  }

  // ------------------- Save clicked skill info -------------------
  Future<void> _saveClickedSkillToFirestore(String skillName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final skillIndex = skillToIndex[skillName.toLowerCase()];
    if (skillIndex == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastClickedSkill': skillName,
        'lastClickedSkillIndex': skillIndex,
        'lastClickedSkillAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving clicked skill: $e');
    }
  }
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search skills...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 0.1,
                        ),
                        cursorColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.clear, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      )
          : _results.isEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 76, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No matching skills found',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: _results.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = _results[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                // --------- Save clicked skill info ---------
                final skillName = item['title']?.toString() ?? '';
                await _saveClickedSkillToFirestore(skillName);
                // --------- Go to skill details page ---------
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SkillDetailsPage(skillId: item['skillId']),
                  ),
                );
              },
              child: SkillCard(
                skillName: item['title'],
                instructor: item['instructor'],
                time: "${item['totalClasses']} classes",
                rating: '4.7',
                exchangeFor: item['exchangeFor'],
                price: item['price'],
              ),
            ),
          );
        },
      ),
    );
  }
}