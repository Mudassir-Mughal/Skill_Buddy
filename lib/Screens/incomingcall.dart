import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
 // <-- MeetingScreen import!
import '../Service/video_api.dart';
import 'meetingscreen.dart'; // <-- Import your VideoSDK token

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String currentUserId;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  StreamSubscription<DocumentSnapshot>? _subscription;
  bool _navigated = false; // Prevent double navigation

  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer().playRingtone();

    _subscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final status = data['status'] as String?;

      if ((status == 'cancelled' || status == 'ended' || status == 'rejected') &&
          mounted &&
          !_navigated) {
        _navigated = true;
        FlutterRingtonePlayer().stop();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _rejectCall(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': 'rejected'});
    } catch (e) {
      debugPrint('Reject call failed: $e');
    } finally {
      FlutterRingtonePlayer().stop();
      if (mounted && !_navigated) {
        _navigated = true;
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _acceptCall(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': 'accepted'});

      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      final receiverName =
          receiverSnapshot.data()?['Fullname'] ?? widget.currentUserId;

      if (mounted && !_navigated) {
        _navigated = true;
        FlutterRingtonePlayer().stop();

        // --- Fetch correct roomId ---
        String? roomId;
        // Try to get from call doc first
        final callDoc = await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.callId)
            .get();
        if (callDoc.exists && callDoc.data() != null) {
          roomId = callDoc.data()!['roomId'];
        }
        // If not found, try lessons collection
        if (roomId == null) {
          final lessonSnap = await FirebaseFirestore.instance
              .collection('lessons')
              .doc(widget.callId)
              .get();
          if (lessonSnap.exists && lessonSnap.data() != null) {
            roomId = lessonSnap.data()!['roomId'];
          }
        }
        roomId ??= widget.callId;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MeetingScreen(
              meetingId: roomId!,
              token: token, displayName: '', // from your video_api.dart
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Accept call failed: $e');
      FlutterRingtonePlayer().stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: const Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              widget.callerName,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "is calling you...",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "reject",
                  backgroundColor: Colors.red,
                  onPressed: () => _rejectCall(context),
                  child: const Icon(Icons.call_end, size: 28),
                ),
                FloatingActionButton(
                  heroTag: "accept",
                  backgroundColor: Colors.green,
                  onPressed: () => _acceptCall(context),
                  child: const Icon(Icons.call, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}