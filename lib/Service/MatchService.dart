import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'KNNsimilarity.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get top matches for the logged-in user
  Future<List<Map<String, dynamic>>> findMatches() async {
    final currentUid = _auth.currentUser?.uid;

    if (currentUid == null) {
      print("❌ No user is logged in!");
      return []; // Return empty list on error
    }

    DocumentSnapshot currentUserDoc =
    await _firestore.collection('users').doc(currentUid).get();

    if (!currentUserDoc.exists) {
      print("❌ Current user not found in Firestore!");
      return []; // Return empty list on error
    }

    Map<String, dynamic> currentUser =
    currentUserDoc.data() as Map<String, dynamic>;

    List<int> currentLearn = (currentUser['skillsToLearnVector'] ?? [])
        .map<int>((e) => (e as num).toInt())
        .toList();
    List<int> currentTeach = (currentUser['skillsToTeachVector'] ?? [])
        .map<int>((e) => (e as num).toInt())
        .toList();

    QuerySnapshot allUsersSnapshot = await _firestore.collection('users').get();

    List<Map<String, dynamic>> matches = [];

    for (var doc in allUsersSnapshot.docs) {
      if (doc.id == currentUid) continue; // skip self

      Map<String, dynamic> other = doc.data() as Map<String, dynamic>;

      List<int> otherLearn = (other['skillsToLearnVector'] ?? [])
          .map<int>((e) => (e as num).toInt())
          .toList();

      List<int> otherTeach = (other['skillsToTeachVector'] ?? [])
          .map<int>((e) => (e as num).toInt())
          .toList();

      int vectorLength = currentLearn.isNotEmpty
          ? currentLearn.length
          : currentTeach.length;
      if (otherLearn.length != vectorLength &&
          otherTeach.length != vectorLength) {
        print("⚠️ Skipping ${other['fullName']} due to vector length mismatch");
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

      matches.add({
        "uid": doc.id,
        "name": other['fullName'],
        "similarity": sim,
      });
    }

    matches.sort((a, b) => b['similarity'].compareTo(a['similarity']));

    // Optionally: print top 3 matches (for debug/log)
    print("🔥 Top Matches for ${currentUser['fullName']} 🔥");
    for (int i = 0; i < matches.length && i < 3; i++) {
      print(
          "${matches[i]['name']} (UID: ${matches[i]['uid']}) → Similarity: ${matches[i]['similarity']}");
    }

    // 💡 RETURN the matches list for UI use!
    return matches;
  }
}