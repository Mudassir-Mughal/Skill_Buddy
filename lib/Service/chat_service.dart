import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../Models/ChatMessage.dart';

class ChatService {
  IO.Socket? _socket;
  final String baseUrl;
  final String userId;

  ChatService({required this.baseUrl, required this.userId});

  void connect() {
    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();
    _socket!.on('connect', (_) => print('[Socket] Connected'));
    _socket!.on('disconnect', (_) => print('[Socket] Disconnected'));
    _socket!.on('error', (data) => print('[Socket] Error: $data'));
  }

  void joinChat(String chatRoomId) {
    _socket?.emit('joinChat', {'chatRoomId': chatRoomId, 'userId': userId});
    print('[Socket] joinChat: $chatRoomId');
  }

  void sendMessage(Map<String, dynamic> message) {
    _socket?.emit('sendMessage', message);
    print('[Socket] sendMessage: $message');
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('receiveMessage', (data) {
      print('[Socket] receiveMessage: $data');
      callback(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory(String peerId) async {
    final url = Uri.parse('$baseUrl/api/chats/$userId/$peerId');
    final response = await http.get(url);
    print('[API] fetchChatHistory: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> sendMessageToApi(Map<String, dynamic> message) async {
    final url = Uri.parse('$baseUrl/api/chats');
    final response = await http.post(url, body: jsonEncode(message), headers: {'Content-Type': 'application/json'});
    print('[API] sendMessageToApi: ${response.statusCode} ${response.body}');
  }

  // Changed to Future, not Stream. Since you are returning from an HTTP call, not a Firestore stream.
  Future<List<String>> getChatPartners(String userId) async {
    final url = Uri.parse('$baseUrl/api/chats/partners/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Expecting backend to return a list of user IDs
      return data.cast<String>();
    }
    return [];
  }

  // Get a user's full name from API
  Future<String> getUserName(String userId) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['Fullname'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }
}