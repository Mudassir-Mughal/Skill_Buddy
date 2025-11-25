class MatchUser {
  final String uid;
  final String name;
  final double similarity;
  final List<String> skillsToTeach;
  final List<String> skillsToLearn;
  MatchUser({
    required this.uid,
    required this.name,
    required this.similarity,
    required this.skillsToTeach,
    required this.skillsToLearn,
  });
}