import 'package:flutter/material.dart';

import '../Models/MatchUser.dart';



class SimilaritySection extends StatelessWidget {
  final String currentUserRole;
  final List<String> currentUserSkillsToLearn;
  final List<String> currentUserSkillsToTeach;
  final Future<List<MatchUser>> similarityMatchesFuture;

  const SimilaritySection({
    Key? key,
    required this.currentUserRole,
    required this.currentUserSkillsToLearn,
    required this.currentUserSkillsToTeach,
    required this.similarityMatchesFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          "Similarity",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MatchUser>>(
          future: similarityMatchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "Failed to load matches",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              );
            }
            final matches = snapshot.data ?? [];
            final filteredMatches = matches.where((m) => m.similarity > 0).toList();
            if (filteredMatches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  "No similar users found.",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMatches.length,
              itemBuilder: (context, index) {
                final match = filteredMatches[index];
                // Find only matched skills
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    elevation: 4,
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    shadowColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                            child: Text(
                              match.name.isNotEmpty ? match.name[0].toUpperCase() : "?",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  match.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Skills matched: ${matchedSkills.join(', ')}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  "Match: ${(match.similarity * 100).toStringAsFixed(0)}%",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}