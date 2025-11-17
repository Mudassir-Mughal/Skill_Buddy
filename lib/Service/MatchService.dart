import 'package:http/http.dart' as http;
import 'dart:convert';
import 'KNNsimilarity.dart';

class MatchService {
  final String baseUrl;
  final String currentUserId;

  MatchService({required this.baseUrl, required this.currentUserId});

  /// Get top matches for the logged-in user
  Future<List<Map<String, dynamic>>> findMatches() async {
    if (currentUserId.isEmpty) {
      print("❌ No user is logged in!");
      return [];
    }

    // Fetch current user from MongoDB
    final currentUserRes = await http.get(Uri.parse('$baseUrl/api/users/$currentUserId'));
    if (currentUserRes.statusCode != 200) {
      print("❌ Current user not found in MongoDB!");
      return [];
    }
    Map<String, dynamic> currentUser = jsonDecode(currentUserRes.body);

    List<int> currentLearn = (currentUser['skillsToLearnVector'] ?? [])
        .map<int>((e) => (e as num).toInt())
        .toList();
    List<int> currentTeach = (currentUser['skillsToTeachVector'] ?? [])
        .map<int>((e) => (e as num).toInt())
        .toList();

    print("Current user role: ${currentUser['role']}");
    print("Current user skillsToLearnVector: $currentLearn");
    print("Current user skillsToTeachVector: $currentTeach");

    // Fetch all users from MongoDB
    final allUsersRes = await http.get(Uri.parse('$baseUrl/api/users'));
    if (allUsersRes.statusCode != 200) {
      print("❌ Failed to fetch users from MongoDB!");
      return [];
    }
    List<dynamic> allUsers = jsonDecode(allUsersRes.body);

    List<Map<String, dynamic>> matches = [];

    for (var other in allUsers) {
      if (other['_id'] == currentUserId) continue; // skip self

      print("Checking user: ${other['Fullname'] ?? other['email'] ?? other['_id']}");
      print("Other user role: ${other['role']}");
      List<int> otherLearn = (other['skillsToLearnVector'] ?? [])
          .map<int>((e) => (e as num).toInt())
          .toList();
      List<int> otherTeach = (other['skillsToTeachVector'] ?? [])
          .map<int>((e) => (e as num).toInt())
          .toList();
      print("Other user skillsToLearnVector: $otherLearn");
      print("Other user skillsToTeachVector: $otherTeach");

      int vectorLength = currentLearn.isNotEmpty
          ? currentLearn.length
          : currentTeach.length;
      if (otherLearn.length != vectorLength &&
          otherTeach.length != vectorLength) {
        print("⚠️ Skipping due to vector length mismatch");
        continue;
      }

      double sim = 0.0;
      if (currentUser['role'] == "Student") {
        sim = cosineSimilarity(currentLearn, otherTeach);
      } else if (currentUser['role'] == "Instructor") {
        sim = cosineSimilarity(currentTeach, otherLearn);
      } else {
        double sim1 = cosineSimilarity(currentLearn, otherTeach);
        double sim2 = cosineSimilarity(currentTeach, otherLearn);
        sim = (sim1 + sim2) / 2;
      }
      print("Similarity score: $sim");

      matches.add({
        "uid": other['_id'],
        "name": other['Fullname'] ?? other['email'] ?? 'Unknown',
        "similarity": sim,
      });
    }

    matches.sort((a, b) => b['similarity'].compareTo(a['similarity']));

    print("🔥 Top Matches for "+(currentUser['Fullname']??currentUser['email']??'Unknown')+" 🔥");
    for (int i = 0; i < matches.length && i < 3; i++) {
      print(
          "${matches[i]['name']} (UID: ${matches[i]['uid']}) → Similarity: ${matches[i]['similarity']}");
    }

    return matches;
  }
}