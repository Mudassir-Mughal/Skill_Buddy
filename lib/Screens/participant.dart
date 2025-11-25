import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';

class ParticipantTile extends StatefulWidget {
  final Participant participant;
  const ParticipantTile({super.key, required this.participant});

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  Stream? videoStream;

  @override
  void initState() {
    super.initState();
    _updateStreams();
    _initStreamListeners();
  }

  void _updateStreams() {
    videoStream = null;
    widget.participant.streams.forEach((key, Stream stream) {
      if (stream.kind == 'video') {
        videoStream = stream;
      }
    });
  }

  void _initStreamListeners() {
    widget.participant.on(Events.streamEnabled, (Stream stream) {
      setState(_updateStreams);
    });

    widget.participant.on(Events.streamDisabled, (Stream stream) {
      setState(_updateStreams);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.participant.displayName ?? "Participant";
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: videoStream != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RTCVideoView(
                videoStream!.renderer as RTCVideoRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
                : Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Center(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}