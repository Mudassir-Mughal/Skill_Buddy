// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
//
// import '../Service/video_service.dart';
//
// class CallPage extends StatefulWidget {
//   final String chatRoomId;
//   final String currentUserId;
//   final String peerId;
//   final bool isCaller;
//
//   CallPage({
//     required this.chatRoomId,
//     required this.currentUserId,
//     required this.peerId,
//     required this.isCaller,
//   });
//
//   @override
//   State<CallPage> createState() => _CallPageState();
// }
//
// class _CallPageState extends State<CallPage> {
//   final _localRenderer = RTCVideoRenderer();
//   final _remoteRenderer = RTCVideoRenderer();
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   bool _micEnabled = true;
//   bool _videoEnabled = true;
//   bool _isFrontCamera = true;
//   bool _callActive = true;
//   bool _remoteDescriptionSet = false;
//
//   final CallService _callService = CallService();
//
//   @override
//   void initState() {
//     super.initState();
//     _initRenderers().then((_) {
//       widget.isCaller ? _makeCallOffer() : _answerIncomingCall();
//     });
//   }
//
//   @override
//   void dispose() {
//     _disposeStreams();
//     super.dispose();
//   }
//
//   Future<void> _disposeStreams() async {
//     // Stop all tracks to release camera/mic
//     if (_localStream != null) {
//       for (var track in _localStream!.getTracks()) {
//         track.stop();
//       }
//       await _localStream!.dispose();
//       _localStream = null;
//     }
//     // Dispose video renderers
//     await _localRenderer.dispose();
//     await _remoteRenderer.dispose();
//     // Close peer connection
//     await _peerConnection?.close();
//     _peerConnection = null;
//   }
//
//   Future<void> _initRenderers() async {
//     await _localRenderer.initialize();
//     await _remoteRenderer.initialize();
//   }
//
//   Future<void> _makeCallOffer() async {
//     final config = {
//       "iceServers": [
//         {"urls": "stun:stun.l.google.com:19302"},
//       ]
//     };
//
//     _peerConnection = await createPeerConnection(config);
//
//     // Local stream
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       "audio": true,
//       "video": {"facingMode": "user"}
//     });
//     _localRenderer.srcObject = _localStream;
//     _localStream?.getTracks().forEach((track) {
//       _peerConnection?.addTrack(track, _localStream!);
//     });
//
//     // REMOTE TRACK HANDLER
//     _peerConnection?.onTrack = (event) {
//       print("onTrack fired! streams: ${event.streams.length}");
//       if (event.streams.isNotEmpty) {
//         print("Assigning remote stream to renderer");
//         setState(() => _remoteRenderer.srcObject = event.streams[0]);
//       }
//     };
//
//     // Fallback for remote stream (older plugin)
//     _peerConnection?.onAddStream = (stream) {
//       print("onAddStream fired!");
//       setState(() => _remoteRenderer.srcObject = stream);
//     };
//
//     // ICE candidate handling
//     _peerConnection?.onIceCandidate = (c) {
//       if (c != null) {
//         print("Caller sending ICE candidate");
//         _callService.addIceCandidate(
//           chatRoomId: widget.chatRoomId,
//           candidateType: 'caller',
//           candidate: {
//             'candidate': c.candidate,
//             'sdpMLineIndex': c.sdpMLineIndex,
//             'sdpMid': c.sdpMid,
//           },
//         );
//       }
//     };
//
//     // Create offer
//     RTCSessionDescription offer = await _peerConnection!.createOffer();
//     await _peerConnection!.setLocalDescription(offer);
//
//     await _callService.createCallOffer(
//       chatRoomId: widget.chatRoomId,
//       callerId: widget.currentUserId,
//       calleeId: widget.peerId,
//       offer: {
//         'sdp': offer.sdp,
//         'type': offer.type,
//       },
//     );
//
//     // Listen for answer
//     _callService.callStream(widget.chatRoomId).listen((doc) async {
//       final data = doc.data();
//       if (data != null && data['answer'] != null && !_remoteDescriptionSet) {
//         final answer = data['answer'];
//         print("Caller received answer SDP");
//         await _peerConnection?.setRemoteDescription(
//             RTCSessionDescription(answer['sdp'], answer['type']));
//         _remoteDescriptionSet = true;
//       }
//     });
//
//     // Listen for callee ICE candidates
//     _callService
//         .candidateStream(widget.chatRoomId, 'callee')
//         .listen((snap) {
//       for (var doc in snap.docs) {
//         final c = doc.data();
//         print("Caller receiving callee ICE candidate");
//         final ice = RTCIceCandidate(
//             c['candidate'], c['sdpMid'], c['sdpMLineIndex']);
//         _peerConnection?.addCandidate(ice);
//       }
//     });
//   }
//
//   Future<void> _answerIncomingCall() async {
//     final config = {
//       "iceServers": [
//         {"urls": "stun:stun.l.google.com:19302"},
//       ]
//     };
//
//     _peerConnection = await createPeerConnection(config);
//
//     // Local stream
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       "audio": true,
//       "video": {"facingMode": "user"}
//     });
//     _localRenderer.srcObject = _localStream;
//     _localStream?.getTracks().forEach((track) {
//       _peerConnection?.addTrack(track, _localStream!);
//     });
//
//     // REMOTE TRACK HANDLER
//     _peerConnection?.onTrack = (event) {
//       print("onTrack fired (callee)! streams: ${event.streams.length}");
//       if (event.streams.isNotEmpty) {
//         print("Callee assigning remote stream to renderer");
//         setState(() => _remoteRenderer.srcObject = event.streams[0]);
//       }
//     };
//
//     // Fallback for remote stream (older plugin)
//     _peerConnection?.onAddStream = (stream) {
//       print("onAddStream fired (callee)!");
//       setState(() => _remoteRenderer.srcObject = stream);
//     };
//
//     // ICE candidate handling
//     _peerConnection?.onIceCandidate = (c) {
//       if (c != null) {
//         print("Callee sending ICE candidate");
//         _callService.addIceCandidate(
//           chatRoomId: widget.chatRoomId,
//           candidateType: 'callee',
//           candidate: {
//             'candidate': c.candidate,
//             'sdpMLineIndex': c.sdpMLineIndex,
//             'sdpMid': c.sdpMid,
//           },
//         );
//       }
//     };
//
//     // Get offer and set as remote
//     final offerDoc = await _callService
//         .callStream(widget.chatRoomId)
//         .firstWhere((doc) => doc.exists && doc.data()?['offer'] != null);
//     final offer = offerDoc.data()!['offer'];
//     print("Callee received offer SDP");
//     await _peerConnection?.setRemoteDescription(
//         RTCSessionDescription(offer['sdp'], offer['type']));
//
//     // Create answer
//     final answerDesc = await _peerConnection!.createAnswer();
//     await _peerConnection!.setLocalDescription(answerDesc);
//
//     await _callService.setCallAnswer(
//       chatRoomId: widget.chatRoomId,
//       answer: {
//         'sdp': answerDesc.sdp,
//         'type': answerDesc.type,
//       },
//     );
//
//     // Listen for caller ICE candidates
//     _callService
//         .candidateStream(widget.chatRoomId, 'caller')
//         .listen((snap) {
//       for (var doc in snap.docs) {
//         final c = doc.data();
//         print("Callee receiving caller ICE candidate");
//         final ice = RTCIceCandidate(
//             c['candidate'], c['sdpMid'], c['sdpMLineIndex']);
//         _peerConnection?.addCandidate(ice);
//       }
//     });
//   }
//
//   Future<void> _hangup() async {
//     setState(() => _callActive = false);
//     await _callService.endCallAndCleanup(widget.chatRoomId);
//     await _disposeStreams();
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     }
//   }
//
//   void _toggleMute() {
//     if (_localStream != null) {
//       _micEnabled = !_micEnabled;
//       _localStream!
//           .getAudioTracks()
//           .forEach((track) => track.enabled = _micEnabled);
//       setState(() {});
//     }
//   }
//
//   void _toggleVideo() {
//     if (_localStream != null) {
//       _videoEnabled = !_videoEnabled;
//       _localStream!
//           .getVideoTracks()
//           .forEach((track) => track.enabled = _videoEnabled);
//       setState(() {});
//     }
//   }
//
//   Future<void> _switchCamera() async {
//     if (_localStream != null) {
//       final videoTracks = _localStream!.getVideoTracks();
//       if (videoTracks.isNotEmpty) {
//         await Helper.switchCamera(videoTracks[0]);
//         _isFrontCamera = !_isFrontCamera;
//         setState(() {});
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 children: [
//                   RTCVideoView(_remoteRenderer),
//                   Positioned(
//                     right: 16,
//                     bottom: 16,
//                     child: Container(
//                       width: 120,
//                       height: 160,
//                       decoration: BoxDecoration(
//                         color: Colors.black38,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: RTCVideoView(_localRenderer, mirror: true),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (_callActive)
//               Container(
//                 color: Colors.black87,
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         _micEnabled ? Icons.mic : Icons.mic_off,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                       onPressed: _toggleMute,
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         Icons.switch_camera,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                       onPressed: _switchCamera,
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         _videoEnabled ? Icons.videocam : Icons.videocam_off,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                       onPressed: _toggleVideo,
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         Icons.call_end,
//                         color: Colors.red,
//                         size: 36,
//                       ),
//                       onPressed: _hangup,
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// call.dart
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  const CallPage({
    Key? key,
    required this.callID,
    required this.currentUserId,
    required this.currentUserName,
    this.appID = 869216330,
    this.appSign = '5b4b309617f6b4de596d9072f171c7bdbaefadb53c77f675a33ae4ad4202873b',
  }) : super(key: key);

  final String callID;
  final String currentUserId;
  final String currentUserName;
  final int appID;
  final String appSign;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: appID,
        appSign: appSign,
        userID: currentUserId,
        userName: currentUserName,
        callID: callID,
        // oneOnOne or group — set whichever fits your flow
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          ..layout = ZegoLayout.gallery(
            // show fullscreen toggle button rules for screen sharing
            showScreenSharingFullscreenModeToggleButtonRules:
            ZegoShowFullscreenModeToggleButtonRules.alwaysShow,
            showNewScreenSharingViewInFullscreenMode: true,
          )
          ..bottomMenuBarConfig = ZegoBottomMenuBarConfig(
            height: 70,
            margin: EdgeInsets.only(bottom: 20),
            buttons: [
              ZegoCallMenuBarButtonName.toggleCameraButton,
              ZegoCallMenuBarButtonName.toggleMicrophoneButton,
              ZegoCallMenuBarButtonName.hangUpButton, // <-- correct button
              ZegoCallMenuBarButtonName.toggleScreenSharingButton, // <-- screen share
            ],
          ),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            defaultAction.call();
          },
        ),
      ),
    );
  }
}
