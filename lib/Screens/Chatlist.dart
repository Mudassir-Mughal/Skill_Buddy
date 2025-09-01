import 'package:flutter/material.dart';
import '../Service/ChatService.dart';
import 'ChatPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListPage extends StatefulWidget {
  final String currentUserId;

  ChatListPage({required this.currentUserId});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();

  Future<String> getUserName(String userId) async {
    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    // Change 'name' to 'Fullname' to match your Firestore field
    return snapshot.data()?['Fullname'] ?? 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<String>>(
        stream: _chatService.getChatPartners(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text("No chats found."));

          final partnerIds = snapshot.data!;
          return ListView.builder(
            itemCount: partnerIds.length,
            itemBuilder: (context, index) {
              final peerId = partnerIds[index];
              return FutureBuilder<String>(
                future: getUserName(peerId),
                builder: (context, nameSnapshot) {
                  if (!nameSnapshot.hasData) {
                    return ListTile(title: Text("Loading..."));
                  }
                  final peerName = nameSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(child: Text(peerName[0])),
                    title: Text(peerName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            currentUserId: widget.currentUserId,
                            peerId: peerId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}