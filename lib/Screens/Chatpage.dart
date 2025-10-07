import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lessonschedule.dart';
import "theme.dart";

const String cloudName = "dthkthzzf";
const String uploadPreset = "unsigned_preset";

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
  String _userRole = "student"; // default role

  @override
  void initState() {
    super.initState();
    chatRoomId = getChatRoomId(widget.currentUserId, widget.peerId);
    _loadUserRole();
  }

  String getChatRoomId(String user1, String user2) {
    return (user1.compareTo(user2) < 0)
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  Future<void> _loadUserRole() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();

    if (userDoc.exists && userDoc.data()?['role'] != null) {
      setState(() {
        _userRole = userDoc.data()!['role'];
      });
    }
  }

  // -------------------- MESSAGE SENDING --------------------

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final timestamp = Timestamp.now();

    final message = {
      'senderId': widget.currentUserId,
      'receiverId': widget.peerId,
      'type': 'text',
      'message': text,
      'timestamp': timestamp,
      'participants': [widget.currentUserId, widget.peerId],
    };

    final chatRoomRef =
    FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);

    await chatRoomRef.set({
      'chatRoomId': chatRoomId,
      'participants': [widget.currentUserId, widget.peerId],
      'lastMessage': text,
      'lastTimestamp': timestamp,
    }, SetOptions(merge: true));

    await chatRoomRef.collection('messages').add(message);
    _controller.clear();
  }

  // -------------------- CLOUDINARY IMAGE UPLOAD --------------------

  Future<String?> _uploadToCloudinary(
      Uint8List fileBytes, String fileName) async {
    final uri =
    Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    try {
      var request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
            http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        print("Cloudinary Upload Failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  // -------------------- ATTACHMENT PICKER --------------------

  void _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: AppColors.primary),
              title: Text('Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        String? url = await _uploadToCloudinary(fileBytes, fileName);

        if (url == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to upload image.")));
          return;
        }

        final timestamp = Timestamp.now();

        final message = {
          'senderId': widget.currentUserId,
          'receiverId': widget.peerId,
          'type': 'image',
          'url': url,
          'timestamp': timestamp,
          'participants': [widget.currentUserId, widget.peerId],
        };

        final chatRoomRef =
        FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);

        await chatRoomRef.set({
          'chatRoomId': chatRoomId,
          'participants': [widget.currentUserId, widget.peerId],
          'lastMessage': '📷 Photo',
          'lastTimestamp': timestamp,
        }, SetOptions(merge: true));

        await chatRoomRef.collection('messages').add(message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
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
          if (_userRole == "instructor" || _userRole == "Both")
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonSchedulePage(
                      currentUserId: widget.currentUserId,
                      peerId: widget.peerId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: AppColors.primary),
              tooltip: 'Schedule Lesson',
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == widget.currentUserId;
                    final msgType = msg['type'] ?? 'text';
                    final deletedFor = msg['deletedFor'] ?? [];

                    if (deletedFor.contains(widget.currentUserId)) {
                      return const SizedBox.shrink();
                    }

                    Widget content;
                    if (msgType == 'text') {
                      content = Text(
                        msg['message'] ?? '',
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.primary,
                          fontSize: 16,
                        ),
                      );
                    } else if (msgType == 'image') {
                      content = GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Image.network(msg['url']),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            msg['url'],
                            height: 180,
                            width: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.broken_image,
                                size: 80, color: Colors.grey),
                          ),
                        ),
                      );
                    } else {
                      content = Text(
                        "Unsupported message type",
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    return GestureDetector(
                      onLongPress: () async {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text("Delete Message"),
                            content:
                            Text("Do you want to delete this message for yourself?"),
                            actions: [
                              TextButton(
                                child: Text("Cancel"),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                              TextButton(
                                child:
                                Text("Delete", style: TextStyle(color: Colors.red)),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final msgId = messages[index].id;
                                  final msgRef = FirebaseFirestore.instance
                                      .collection('chatRooms')
                                      .doc(chatRoomId)
                                      .collection('messages')
                                      .doc(msgId);
                                  List<dynamic> alreadyDeletedFor =
                                      deletedFor ?? [];
                                  if (!alreadyDeletedFor
                                      .contains(widget.currentUserId)) {
                                    await msgRef.update({
                                      'deletedFor':
                                      FieldValue.arrayUnion([widget.currentUserId])
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Align(
                        alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.70,
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
                              bottomLeft:
                              Radius.circular(isMe ? 18 : 4),
                              bottomRight:
                              Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: content,
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
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: _pickAttachment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.attach_file,
                          color: AppColors.primary, size: 26),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.13)),
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
