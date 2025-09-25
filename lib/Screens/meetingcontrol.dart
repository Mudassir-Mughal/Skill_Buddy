import 'package:flutter/material.dart';

class MeetingControls extends StatelessWidget {
  final bool micEnabled;
  final bool camEnabled;
  final bool isScreenSharing;
  final bool speakerOn;
  final VoidCallback onToggleMicButtonPressed;
  final VoidCallback onToggleCameraButtonPressed;
  final VoidCallback onScreenSharePressed;
  final VoidCallback onSpeakerTogglePressed;
  final VoidCallback onLeaveButtonPressed;
  final VoidCallback? onMorePressed;

  const MeetingControls({
    Key? key,
    required this.micEnabled,
    required this.camEnabled,
    required this.isScreenSharing,
    required this.speakerOn,
    required this.onToggleMicButtonPressed,
    required this.onToggleCameraButtonPressed,
    required this.onScreenSharePressed,
    required this.onSpeakerTogglePressed,
    required this.onLeaveButtonPressed,
    this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _circleButton(
              icon: Icons.mic,
              isOff: !micEnabled,
              onPressed: onToggleMicButtonPressed,
              color: Colors.blueAccent,
            ),
            _circleButton(
              icon: Icons.videocam,
              isOff: !camEnabled,
              onPressed: onToggleCameraButtonPressed,
              color: Colors.purpleAccent,
            ),
            _circleButton(
              icon: Icons.screen_share,
              isOff: !isScreenSharing,
              onPressed: onScreenSharePressed,
              color: Colors.greenAccent,
            ),
            _circleButton(
              icon: Icons.volume_up,
              isOff: !speakerOn,
              onPressed: onSpeakerTogglePressed,
              color: Colors.orangeAccent,
            ),
            if (onMorePressed != null)
              _circleButton(
                icon: Icons.more_vert,
                onPressed: onMorePressed!,
                color: Colors.grey,
              ),
            _circleButton(
              icon: Icons.call_end,
              onPressed: onLeaveButtonPressed,
              color: Colors.redAccent,
              iconColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isOff = false,
    Color iconColor = Colors.black87,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(icon, color: iconColor),
            onPressed: onPressed,
            iconSize: 28,
            splashRadius: 24,
          ),
        ),
        if (isOff)
          Positioned(
            left: 8,
            right: 8,
            top: 20,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}