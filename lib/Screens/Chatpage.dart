import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/videocall.dart';
import 'Outgoingcall.dart';
import 'incomingcall.dart';
import "theme.dart";

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String peerId;

  ChatPage({required this.currentUserId, required this.peerId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  late String chatRoomId;

  StreamSubscription<QuerySnapshot>? _callSub;
  bool _isShowingIncomingDialog = false;

  @override
  void initState() {
    super.initState();
    chatRoomId = getChatRoomId(widget.currentUserId, widget.peerId);
    _listenForIncomingCalls();
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  String getChatRoomId(String user1, String user2) {
    return (user1.compareTo(user2) < 0)
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final timestamp = Timestamp.now();

    final message = {
      'senderId': widget.currentUserId,
      'receiverId': widget.peerId,
      'message': text,
      'timestamp': timestamp,
      'participants': [widget.currentUserId, widget.peerId],
    };

    final chatRoomRef = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId);

    await chatRoomRef.set({
      'chatRoomId': chatRoomId,
      'participants': [widget.currentUserId, widget.peerId],
      'lastMessage': text,
      'lastTimestamp': timestamp,
    }, SetOptions(merge: true));

    await chatRoomRef.collection('messages').add(message);
    _controller.clear();
  }

  // -------------------- CALLING LOGIC --------------------

  Future<void> _startVideoCall() async {
    final callerId = widget.currentUserId;
    final receiverId = widget.peerId;

    // create unique callId
    final callId = '${callerId}_to_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';

    // fetch both names (if available)
    final callerSnap = await FirebaseFirestore.instance.collection('users').doc(callerId).get();
    final receiverSnap = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();

    final callerName = callerSnap.data()?['Fullname'] ?? callerId;
    final receiverName = receiverSnap.data()?['Fullname'] ?? receiverId;

    // create call doc
    final callDocRef = FirebaseFirestore.instance.collection('calls').doc(callId);
    await callDocRef.set({
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'status': 'ringing', // ringing | accepted | rejected | ended | cancelled
      'createdAt': FieldValue.serverTimestamp(),
    });

    // navigate to outgoing screen (it will wait for status changes)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          callId: callId,
          callerId: callerId,
          callerName: callerName,
          receiverId: receiverId,
          receiverName: receiverName,
        ),
      ),
    );
  }


  void _listenForIncomingCalls() {
    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final callerId = data['callerId'] as String? ?? 'Unknown';

      if (callerId == widget.currentUserId) return;

      if (!_isShowingIncomingDialog) {
        _showIncomingCallScreen(doc);
      }
    }, onError: (e) {
      debugPrint('Incoming call listen error: $e');
    });
  }

  void _showIncomingCallScreen(QueryDocumentSnapshot doc) async {
    setState(() => _isShowingIncomingDialog = true);

    final data = doc.data() as Map<String, dynamic>;
    final callerId = data['callerId'] as String? ?? 'Unknown';
    final callId = data['callId'];

    // 🔹 Fetch caller name
    final callerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(callerId)
        .get();
    final callerName = callerSnapshot.data()?['Fullname'] ?? callerId;

    // 🔹 Navigate to full screen instead of dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: callId,
          callerId: callerId,
          callerName: callerName,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) {
      // reset flag when screen is popped
      setState(() => _isShowingIncomingDialog = false);
    });
  }


  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Chat',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _startVideoCall,
            icon: const Icon(Icons.video_call, color: AppColors.primary),
            tooltip: 'Start video call',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == widget.currentUserId;
                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.70,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        margin: EdgeInsets.only(
                          bottom: 8,
                          top: index == 0 ? 8 : 0,
                          left: isMe ? 40 : 0,
                          right: isMe ? 0 : 40,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.chatMe
                              : AppColors.chatPeer,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 2,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['message'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors.primary.withOpacity(0.13)),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.16),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
