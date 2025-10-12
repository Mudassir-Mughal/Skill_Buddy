import 'package:flutter/material.dart';
import '../Models/MatchUser.dart';

class SimilaritySectionWeb extends StatelessWidget {
  final String currentUserRole;
  final List<String> currentUserSkillsToLearn;
  final List<String> currentUserSkillsToTeach;
  final Future<List<MatchUser>> similarityMatchesFuture;

  const SimilaritySectionWeb({
    Key? key,
    required this.currentUserRole,
    required this.currentUserSkillsToLearn,
    required this.currentUserSkillsToTeach,
    required this.similarityMatchesFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Similarity",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<MatchUser>>(
            future: similarityMatchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    "Failed to load matches",
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red, fontSize: 18),
                  ),
                );
              }
              final matches = snapshot.data ?? [];
              final filteredMatches = matches.where((m) => m.similarity > 0).toList();
              if (filteredMatches.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    "No similar users found.",
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey, fontSize: 18),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredMatches.length,
                separatorBuilder: (context, _) => SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final match = filteredMatches[index];
                  List<String> matchedSkills = [];
                  if (currentUserRole == "Student") {
                    matchedSkills = currentUserSkillsToLearn.toSet().intersection(match.skillsToTeach.toSet()).toList();
                  } else if (currentUserRole == "Instructor") {
                    matchedSkills = currentUserSkillsToTeach.toSet().intersection(match.skillsToLearn.toSet()).toList();
                  } else {
                    final a = currentUserSkillsToLearn.toSet().intersection(match.skillsToTeach.toSet());
                    final b = currentUserSkillsToTeach.toSet().intersection(match.skillsToLearn.toSet());
                    matchedSkills = [...a, ...b];
                  }
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.14),
                              child: Text(
                                match.name.isNotEmpty ? match.name[0].toUpperCase() : "?",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                              ),
                            ),
                            SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    match.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: theme.colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Skills matched: ${matchedSkills.join(', ')}",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Text(
                                "Match: ${(match.similarity * 100).toStringAsFixed(0)}%",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}