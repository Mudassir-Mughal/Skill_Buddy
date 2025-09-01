// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../Screens/videocall.dart';
//
// class CallService {
//   static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//
//   /// Save device FCM token in Firestore for each user
//   static Future<void> saveDeviceToken(String userId) async {
//     String? token = await _fcm.getToken();
//     if (token != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .update({'fcmToken': token});
//     }
//   }
//
//   /// Teacher sends call notification to Student
//   static Future<void> sendCallNotification({
//     required String callerId,
//     required String receiverId,
//     required String meetingId,
//     required String serverKey, // Your Firebase Cloud Messaging server key
//   }) async {
//     // get receiver token
//     var doc = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
//     String? token = doc['fcmToken'];
//
//     if (token == null) return;
//
//     final url = Uri.parse("https://fcm.googleapis.com/fcm/send");
//     final payload = {
//       "to": token,
//       "data": {
//         "type": "incoming_call",
//         "meetingId": meetingId,
//         "callerId": callerId,
//       },
//       "notification": {
//         "title": "Incoming Call",
//         "body": "Tap to join the video call",
//       }
//     };
//
//     await http.post(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "key=$serverKey",
//       },
//       body: jsonEncode(payload),
//     );
//   }
//
//   /// Handle incoming calls
//   static void initializeCallListener(GlobalKey<NavigatorState> navigatorKey) {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (message.data['type'] == 'incoming_call') {
//         String meetingId = message.data['meetingId'];
//         String callerId = message.data['callerId'];
//
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (_) => IncomingCallScreen(
//               meetingId: meetingId,
//               callerId: callerId,
//             ),
//           ),
//         );
//       }
//     });
//   }
// }
