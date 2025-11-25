import 'dart:convert';
import 'package:http/http.dart' as http;

//Auth token we will use to generate a meeting and connect to it
String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiJmYTJjMjFjOS04ZjFkLTRjNWItYWUzMS1jMTAxNzlmMjUwNjEiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sImlhdCI6MTc1NTY3NDIwMCwiZXhwIjoxNzg3MjEwMjAwfQ.164Q9dk8NQDwYsRzRDC0bgin3TwtFExNlRc4hHAIFdU";

// API call to create meeting
Future<String> createMeeting() async {
  final http.Response httpResponse = await http.post(
    Uri.parse("https://api.videosdk.live/v2/rooms"),
    headers: {'Authorization': token},
  );

//Destructuring the roomId from the response
  return json.decode(httpResponse.body)['roomId'];
}