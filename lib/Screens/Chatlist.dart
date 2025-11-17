import 'package:flutter/material.dart';
import '../Service/chat_service.dart';
import 'ChatPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatListPage extends StatefulWidget {
  final String currentUserId;
  final String baseUrl; // Add baseUrl for MongoDB API

  ChatListPage({required this.currentUserId, required this.baseUrl});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(baseUrl: widget.baseUrl, userId: widget.currentUserId);
  }

  Future<String> getUserName(String userId) async {
    return await _chatService.getUserName(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<String>>(
        future: _chatService.getChatPartners(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          // Debug print for chat partners
          print('Chat partners for user ${widget.currentUserId}: ${snapshot.data}');

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