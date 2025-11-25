import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

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
    _socket?.emit('joinRoom', {'chatRoomId': chatRoomId, 'userId': userId});
    print('[Socket] joinRoom: $chatRoomId');
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
    print('[ChatService] onReceiveMessage listener registered');
  }

  void offReceiveMessage() {
    if (_socket != null) {
      _socket!.off('receiveMessage');
      print('[ChatService] offReceiveMessage called, listener removed');
    }
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
    } else {
      print('[API] Error fetching chat history: ${response.statusCode}');
      return [];
    }
  }

  Future<bool> sendMessageToApi(Map<String, dynamic> message) async {
    final url = Uri.parse('$baseUrl/api/chats');
    final response = await http.post(url, body: jsonEncode(message), headers: {'Content-Type': 'application/json'});
    print('[API] sendMessageToApi: ${response.statusCode} ${response.body}');
    return response.statusCode == 201;
  }

  Future<List<String>> getChatPartners(String userId) async {
    final url = Uri.parse('$baseUrl/api/chats/partners/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      print('[API] Error fetching chat partners: ${response.statusCode}');
      return [];
    }
  }

  Future<String> getUserName(String userId) async {
    final url = Uri.parse('$baseUrl/api/users/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return (data['Fullname'] != null && data['Fullname'].toString().trim().isNotEmpty)
          ? data['Fullname']
          : 'Unknown User';
    } else {
      print('[API] Error fetching user name: ${response.statusCode}');
      return 'Unknown User';
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatList(String userId) async {
    final url = Uri.parse('$baseUrl/api/chats/chatlist/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      print('[API] Error fetching chat list: \\${response.statusCode}');
      return [];
    }
  }

  IO.Socket? get socket => _socket;
}