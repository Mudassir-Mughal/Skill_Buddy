import 'package:cloud_firestore/cloud_firestore.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new call document with offer (signaling)
  Future<void> createCallOffer({
    required String chatRoomId,
    required String callerId,
    required String calleeId,
    required Map<String, dynamic> offer,
  }) async {
    final callRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('calls')
        .doc('activeCall');

    await callRef.set({
      'callerId': callerId,
      'calleeId': calleeId,
      'offer': offer,
      'answer': null,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Set answer from callee
  Future<void> setCallAnswer({
    required String chatRoomId,
    required Map<String, dynamic> answer,
  }) async {
    final callRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('calls')
        .doc('activeCall');
    await callRef.update({'answer': answer});
  }

  /// Add ICE candidate to subcollection
  Future<void> addIceCandidate({
    required String chatRoomId,
    required String candidateType, // 'caller' or 'callee'
    required Map<String, dynamic> candidate,
  }) async {
    final candidatesRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('calls')
        .doc('activeCall')
        .collection('${candidateType}_candidates');
    await candidatesRef.add(candidate);
  }

  /// Listen for call document
  Stream<DocumentSnapshot<Map<String, dynamic>>> callStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('calls')
        .doc('activeCall')
        .snapshots();
  }

  /// Listen for ICE candidates
  Stream<QuerySnapshot<Map<String, dynamic>>> candidateStream(
      String chatRoomId, String candidateType) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('calls')
        .doc('activeCall')
        .collection('${candidateType}_candidates')
        .snapshots();
  }

  /// End call and cleanup docs
  Future<void> endCallAndCleanup(String chatRoomId) async {
    final callDocRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('calls')
        .doc('activeCall');

    // Delete candidates subcollections
    final callerCandidates = await callDocRef.collection('caller_candidates').get();
    for (var doc in callerCandidates.docs) {
      await doc.reference.delete();
    }
    final calleeCandidates = await callDocRef.collection('callee_candidates').get();
    for (var doc in calleeCandidates.docs) {
      await doc.reference.delete();
    }

    await callDocRef.delete();
  }
}