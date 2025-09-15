import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'videocall.dart'; // Your CallPage

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
  bool _navigated = false; // ✅ Prevent double navigation

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
      // Stop ringtone when rejecting
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

        // Stop ringtone when accepting
        FlutterRingtonePlayer().stop();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallPage(
              callID: widget.callId,
              currentUserId: widget.currentUserId,
              currentUserName: receiverName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Accept call failed: $e');
      FlutterRingtonePlayer().stop(); // fallback in case of error
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
