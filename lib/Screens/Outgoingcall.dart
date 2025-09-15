import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'videocall.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;

  const OutgoingCallScreen({
    Key? key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  _OutgoingCallScreenState createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  StreamSubscription<DocumentSnapshot>? _callSub;
  String _status = 'ringing';
  bool _navigated = false; // ✅ Prevent multiple navs

  @override
  void initState() {
    super.initState();
    _listenCallDoc();
  }

  void _listenCallDoc() {
    final docRef =
    FirebaseFirestore.instance.collection('calls').doc(widget.callId);
    _callSub = docRef.snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? 'ringing';

      if (status == _status) return;
      setState(() => _status = status);

      if (!_navigated) {
        if (status == 'accepted') {
          _navigated = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CallPage(
                callID: widget.callId,
                currentUserId: widget.callerId,
                currentUserName: widget.callerName,
              ),
            ),
          );
        } else if (status == 'rejected') {
          _navigated = true;
          Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call was rejected')),
              );
            }
          });
        } else if (status == 'cancelled' || status == 'ended') {
          _navigated = true;
          Navigator.of(context).pop();
        }
      }
    }, onError: (e) {
      debugPrint('Outgoing call listen error: $e');
    });
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  Future<void> _cancelCall() async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to cancel call doc: $e');
    } finally {
      if (mounted && !_navigated) {
        _navigated = true;
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white12,
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.receiverName,
              style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _status == 'ringing' ? 'Ringing...' : _status,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'cancel_call',
                    backgroundColor: Colors.red,
                    onPressed: _cancelCall,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
