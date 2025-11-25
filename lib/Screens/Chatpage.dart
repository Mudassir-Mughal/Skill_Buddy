import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show Platform, Directory, File;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'lessonschedule.dart';
import 'theme.dart';
import '../Service/chat_service.dart';
import 'package:skill_buddy_fyp/Service/api_service.dart';
import '../config.dart';

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
  late ChatService _chatService;
  List<Map<String, dynamic>> messages = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();
  Set<String> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    chatRoomId = getChatRoomId(widget.currentUserId, widget.peerId);
    _chatService = ChatService(baseUrl: baseUrl, userId: widget.currentUserId);
    _initChat();
    _loadUserRole();
  }

  Future<void> _initChat() async {
    _chatService.connect();
    _chatService.joinChat(chatRoomId);
    _chatService.offReceiveMessage(); // Always remove previous listener to avoid stacking
    final history = await _chatService.fetchChatHistory(widget.peerId);
    final keys = history.map(_msgKey).toSet();
    setState(() {
      messages = history;
      _messageKeys = keys;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    // Only set the socket listener after history is loaded and keys are set
    _chatService.onReceiveMessage((msg) {
      final key = _msgKey(msg);
      if (!_messageKeys.contains(key)) {
        setState(() {
          messages.add(msg);
          _messageKeys.add(key);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
    print('[ChatPage] Socket listener registered for receiveMessage');
  }

  String _msgKey(Map<String, dynamic> msg) {
    // Use timestamp + senderId as a unique key
    return (msg['timestamp'] ?? '') + '_' + (msg['senderId'] ?? '');
  }

  String getChatRoomId(String user1, String user2) {
    return (user1.compareTo(user2) < 0)
        ? '${user1}_$user2'
        : '${user2}_$user1';
  }

  Future<void> _loadUserRole() async {
    final profile = await ApiService.getUserProfile(widget.currentUserId);
    if (profile != null && profile['role'] != null) {
      setState(() {
        _userRole = profile['role'].toString().toLowerCase();
      });
    }
  }

  // Only add message to UI in onReceiveMessage. Do NOT add here.
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final timestamp = DateTime.now().toIso8601String();
    final message = {
      'senderId': widget.currentUserId,
      'receiverId': widget.peerId,
      'type': 'text',
      'message': text,
      'timestamp': timestamp,
      'participants': [widget.currentUserId, widget.peerId],
      'chatRoomId': chatRoomId,
    };
    _chatService.sendMessage(message); // Real-time via socket
    await _chatService.sendMessageToApi(message); // Ensure backend updates
    _controller.clear();
  }

  // Upload file directly to Cloudinary (unsigned)
  Future<String?> _uploadToCloudinary(
      Uint8List fileBytes, String fileName, String resourceType) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        String rawUrl = data['secure_url'];
        String fixedUrl = rawUrl.replaceFirst('/upload/', '/upload/fl_attachment/');
        print("Uploaded to Cloudinary: $fixedUrl");
        return fixedUrl;
      } else {
        print("Cloudinary upload failed: "+response.reasonPhrase.toString());
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // Only add message to UI in onReceiveMessage. Do NOT add here.
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
        String? url = await _uploadToCloudinary(fileBytes, fileName, "image");
        if (url == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to upload image.")));
          return;
        }
        final timestamp = DateTime.now().toIso8601String();
        final message = {
          'senderId': widget.currentUserId,
          'receiverId': widget.peerId,
          'type': 'image',
          'url': url,
          'fileName': fileName,
          'timestamp': timestamp,
          'participants': [widget.currentUserId, widget.peerId],
          'chatRoomId': chatRoomId,
        };
        _chatService.sendMessage(message); // Real-time via socket
        await _chatService.sendMessageToApi(message); // Ensure backend updates
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Only add message to UI in onReceiveMessage. Do NOT add here.
  Future<void> _pickAndSendWordDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        String? url = await _uploadToCloudinary(fileBytes, fileName, "raw");
        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload Word document.")),
          );
          return;
        }
        final timestamp = DateTime.now().toIso8601String();
        final message = {
          'senderId': widget.currentUserId,
          'receiverId': widget.peerId,
          'type': 'document',
          'fileName': fileName,
          'url': url,
          'timestamp': timestamp,
          'participants': [widget.currentUserId, widget.peerId],
          'chatRoomId': chatRoomId,
        };
        _chatService.sendMessage(message); // Real-time via socket
        await _chatService.sendMessageToApi(message); // Ensure backend updates
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Word document sent successfully!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking/sending Word document: $e")));
    }
  }

  Future<bool> requestStoragePermission() async {
    // Only for mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 30) {
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
          return status.isGranted;
        } else {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        }
      }
      // iOS: permission handled by default
      return true;
    }
    return true;
  }

  Future<void> downloadToDownloadsFolder(String url, String fileName) async {
    if (kIsWeb) {
      // On web, just open the url in browser (will trigger download if fl_attachment is set)
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not download/open in browser.")),
        );
      }
      return;
    }

    Directory? downloadsDir;
    bool permissionGranted = await requestStoragePermission();
    if (permissionGranted) {
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        downloadsDir = await getDownloadsDirectory();
      }
      if (downloadsDir != null) {
        final filePath = "${downloadsDir.path}/$fileName";
        try {
          final response = await Dio().download(url, filePath);
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Downloaded to: $filePath")),
            );
            // DO NOT open file after download, just notify user
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Download failed. Try again.")),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download failed: $e")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage permission denied!"))
      );
      openAppSettings();
    }
  }

  // Download image to gallery (Android/iOS)
  Future<void> downloadToGallery(String url, String fileName) async {
    try {
      if (kIsWeb) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not download/open in browser.")),
          );
        }
        return;
      }
      // Request permission before saving
      bool permissionGranted = await requestStoragePermission();
      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage/gallery permission denied!")),
        );
        return;
      }
      // Download image bytes
      final response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
      final bytes = response.data;
      if (bytes == null) throw Exception("Failed to download image bytes");
      if (Platform.isAndroid || Platform.isIOS) {
        // Save image to device storage using path_provider and dart:io
        final directory = await getExternalStorageDirectory();
        if (directory == null) throw Exception("Cannot access storage directory");
        final String dirPath = directory.path;
        final String filePath = '$dirPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image saved to: $filePath")),
        );
      } else {
        await downloadToDownloadsFolder(url, fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    // TODO: Implement delete message via API if needed
    // Optionally emit a socket event for delete
    print('[Chat] Delete message $messageId (not implemented)');
  }

  // Scroll to bottom helper
  void _scrollToBottom() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _chatService.offReceiveMessage(); // Remove listener to prevent stacking
    _chatService.disconnect();
    super.dispose();
  }

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
            ListTile(
              leading: Icon(Icons.description, color: AppColors.primary),
              title: Text('Document'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendWordDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

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
              backgroundColor: AppColors.primary.withAlpha((255 * 0.15).toInt()),
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
          if (_userRole == "instructor" || _userRole == "both")
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId'] == widget.currentUserId;
                          final msgType = msg['type'] ?? 'text';
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
                            final fileName = msg['fileName'] ?? 'image.jpg';
                            final url = msg['url'];
                            content = Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    // Open image in full screen dialog
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: InteractiveViewer(
                                          child: Image.network(url, fit: BoxFit.contain),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      url,
                                      height: 180,
                                      width: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () async {
                                      await downloadToGallery(url, fileName);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha((255 * 0.8).toInt()),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (msgType == 'document') {
                            final fileName = msg['fileName'] ?? 'Document.docx';
                            final url = msg['url'];
                            final fileIcon = _getFileIcon(fileName);
                            if (!(fileName.toLowerCase().endsWith('.doc') || fileName.toLowerCase().endsWith('.docx'))) {
                              return const SizedBox.shrink();
                            }
                            content = InkWell(
                              onTap: () async {
                                await downloadToDownloadsFolder(url, fileName);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withAlpha((255 * 0.15).toInt()),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(fileIcon, color: AppColors.primary, size: 28),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
                                  ],
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
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Delete Message'),
                                  content: Text('Do you want to delete this message?'),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    TextButton(
                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _deleteMessage(msg['id'] ?? '');
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.70,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                margin: EdgeInsets.only(
                                  bottom: 8,
                                  top: index == 0 ? 8 : 0,
                                  left: isMe ? 40 : 0,
                                  right: isMe ? 0 : 40,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.chatMe : AppColors.chatPeer,
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
                                child: content,
                              ),
                            ),
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
                            color: AppColors.primary.withAlpha((255 * 0.13).toInt())),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            color: AppColors.primary.withAlpha((255 * 0.16).toInt()),
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

