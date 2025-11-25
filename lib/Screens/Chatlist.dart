import 'package:flutter/material.dart';
import '../Service/chat_service.dart';
import 'ChatPage.dart';

class ChatListPage extends StatefulWidget {
  final String currentUserId;
  final String baseUrl; // Add baseUrl for MongoDB API

  ChatListPage({required this.currentUserId, required this.baseUrl});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatService _chatService;
  late Future<List<Map<String, dynamic>>> _chatListFuture;
  late final GlobalKey<RefreshIndicatorState> _refreshKey;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(baseUrl: widget.baseUrl, userId: widget.currentUserId);
    _refreshKey = GlobalKey<RefreshIndicatorState>();
    _chatListFuture = _chatService.fetchChatList(widget.currentUserId);
  }

  Future<void> _refreshChatList() async {
    setState(() {
      _chatListFuture = _chatService.fetchChatList(widget.currentUserId);
    });
    await _chatListFuture;
  }

  Future<String> getUserName(String userId) async {
    return await _chatService.getUserName(userId);
  }

  String _formatTime(dynamic rawTime) {
    try {
      final DateTime time = DateTime.parse(rawTime.toString()).toLocal();
      final String hour = time.hour.toString().padLeft(2, '0');
      final String minute = time.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[ChatListPage] userId: \\${widget.currentUserId}');
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshChatList,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _chatListFuture,
          builder: (context, snapshot) {
            print('[ChatListPage] snapshot.hasData: \\${snapshot.hasData}, error: \\${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: CircularProgressIndicator());

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              print('[ChatListPage] No chats found. Raw data: \\${snapshot.data}');
              return Center(child: Text("No chats found."));
            }

            final chatRooms = snapshot.data!;
            return ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                final peerId = (room['participants'] as List).firstWhere((id) => id != widget.currentUserId, orElse: () => '');
                return FutureBuilder<String>(
                  future: getUserName(peerId),
                  builder: (context, nameSnapshot) {
                    final peerName = nameSnapshot.data ?? 'Loading...';
                    return ListTile(
                      leading: CircleAvatar(child: Text(peerName.isNotEmpty ? peerName[0] : '?')),
                      title: Text(peerName),
                      subtitle: Text(room['lastMessage'] ?? ''),
                      trailing: room['lastMessageTime'] != null
                          ? Text(
                        _formatTime(room['lastMessageTime']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                          : null,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              currentUserId: widget.currentUserId,
                              peerId: peerId,
                            ),
                          ),
                        );
                        _refreshChatList(); // Refresh chat list after returning
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}