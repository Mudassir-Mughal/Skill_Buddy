// import 'package:flutter/material.dart';
// import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
//
// class IncomingCallScreen extends StatelessWidget {
//   final String meetingId;
//   final String callerId;
//
//   const IncomingCallScreen({
//     Key? key,
//     required this.meetingId,
//     required this.callerId,
//   }) : super(key: key);
//
//   void _joinMeeting(BuildContext context) {
//     final jitsi = JitsiMeet();
//     var options = JitsiMeetConferenceOptions(
//       room: meetingId,
//       configOverrides: {
//         "startWithAudioMuted": false,
//         "startWithVideoMuted": false,
//       },
//       userInfo: JitsiMeetUserInfo(
//         displayName: "User", // you can pass currentUserId
//       ),
//     );
//     jitsi.join(options);
//     Navigator.pop(context); // close incoming call screen
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black54,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text("Incoming Call from $callerId",
//                 style: const TextStyle(color: Colors.white, fontSize: 22)),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 FloatingActionButton(
//                   backgroundColor: Colors.green,
//                   onPressed: () => _joinMeeting(context),
//                   child: const Icon(Icons.call),
//                 ),
//                 const SizedBox(width: 40),
//                 FloatingActionButton(
//                   backgroundColor: Colors.red,
//                   onPressed: () => Navigator.pop(context),
//                   child: const Icon(Icons.call_end),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
