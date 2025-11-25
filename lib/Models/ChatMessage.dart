class ChatMessage {
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final List<String> participants;  // <-- Add this

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.participants,  // <-- Add this
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'participants': participants,   // <-- Add this
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      participants: List<String>.from(map['participants']),  // <-- Add this
    );
  }
}
