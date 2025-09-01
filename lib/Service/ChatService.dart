import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/ChatMessage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a new message to chat room
  Future<void> sendMessage(ChatMessage message, String chatRoomId) async {
    final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);

    // Ensure chat room exists
    await chatRoomRef.set({
      'chatRoomId': chatRoomId,
      'participants': [message.senderId, message.receiverId],
      'lastMessage': message.message,
      'lastTimestamp': message.timestamp,
    }, SetOptions(merge: true));

    // Save message
    await chatRoomRef.collection('messages').add({
      'message': message.message,
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'timestamp': message.timestamp,
      'participants': [message.senderId, message.receiverId],
    });
  }


  /// Get real-time messages from a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()))
        .toList());
  }

  /// Get list of chat partners by fetching chatRooms where user is participant
  Stream<List<String>> getChatPartners(String userId) {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((querySnapshot) {
      Set<String> partnerIds = {};
      for (var doc in querySnapshot.docs) {
        List<dynamic> participants = doc.data()['participants'] ?? [];
        for (var participant in participants) {
          if (participant != userId) {
            partnerIds.add(participant);
          }
        }
      }
      return partnerIds.toList();
    });
  }

}
