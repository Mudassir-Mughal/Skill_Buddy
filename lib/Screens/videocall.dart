import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/participant.dart';
import 'package:videosdk/videosdk.dart';
import 'package:skill_buddy_fyp/Service/api_service.dart';

class MeetingScreen extends StatefulWidget {
  final String meetingId;
  final String token;

  const MeetingScreen({
    super.key,
    required this.meetingId,
    required this.token,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  late Room _room;
  bool micEnabled = true;
  bool camEnabled = true;
  bool isScreenSharing = false;
  bool speakerOn = true;
  bool showScreenShareFull = false;

  Map<String, Participant> participants = {};
  String? presenterId;
  bool controlsVisible = true;
  bool _navigated = false;
  String displayName = "User";

  @override
  void initState() {
    super.initState();
    fetchDisplayName();
  }

  Future<void> fetchDisplayName() async {
    final userId = ApiService.currentUserId;
    if (userId == null) return;
    final userDoc = await ApiService.getUserProfile(userId);
    displayName = userDoc?['Fullname'] ?? "User";
    initializeRoom();
  }

  void initializeRoom() {
    _room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: displayName,
      micEnabled: micEnabled,
      camEnabled: camEnabled,
      defaultCameraIndex: kIsWeb ? 0 : 1,
    );
    setMeetingEventListener();
    _room.join();
  }

  @override
  void dispose() {
    try {
      _room.leave();
    } catch (_) {}
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void setMeetingEventListener() {
    _room.on(Events.roomJoined, () {
      setState(() {
        participants[_room.localParticipant.id] = _room.localParticipant;
      });
    });

    _room.on(Events.participantJoined, (Participant participant) {
      setState(() {
        participants[participant.id] = participant;
      });
    });

    _room.on(Events.participantLeft, (String participantId) {
      setState(() {
        participants.remove(participantId);
        if (presenterId == participantId) {
          presenterId = null;
          showScreenShareFull = false;
        }
      });
    });

    _room.on(Events.roomLeft, () {
      participants.clear();
      if (!_navigated) {
        _navigated = true;
        Navigator.of(context).pop();
      }
    });

    _room.on(Events.presenterChanged, (String? activePresenterId) {
      setState(() {
        presenterId = activePresenterId;
        isScreenSharing = activePresenterId == _room.localParticipant.id;
        showScreenShareFull = false;
      });
    });

    _room.on(Events.streamDisabled, (Participant participant, Stream stream) {
      if (stream.kind!.toLowerCase().contains('screen') ||
          stream.kind?.toLowerCase() == 'share') {
        setState(() {
          if (presenterId == participant.id) {
            presenterId = null;
            showScreenShareFull = false;
          }
        });
      }
    });
  }

  void _shareScreen() async {
    try {
      if (!isScreenSharing) {
        await _room.enableScreenShare();
        setState(() {
          isScreenSharing = true;
        });
      } else {
        await _room.disableScreenShare();
        setState(() {
          isScreenSharing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen share failed: $e')),
      );
    }
  }

  Widget _buildScreenShareView({bool full = false}) {
    if (presenterId == null) return const SizedBox.shrink();
    final presenter = participants[presenterId];
    if (presenter == null) return const SizedBox.shrink();

    dynamic shareStream;
    for (var s in presenter.streams.values) {
      final kind = (s.kind ?? '').toString().toLowerCase();
      if (kind == 'share' || kind.contains('screen')) {
        shareStream = s;
        break;
      }
    }

    if (shareStream == null) {
      return const Center(child: Text("Waiting for screen share..."));
    }
    final renderer = shareStream.renderer;
    if (renderer == null) {
      return const Center(child: Text("Preparing screen share..."));
    }

    final widgetVideo = RTCVideoView(
      renderer as RTCVideoRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );

    if (full) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(child: widgetVideo),
            SafeArea(
              child: Positioned(
                right: 16,
                top: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => setState(() => showScreenShareFull = false),
                  tooltip: "Close Full Screen",
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: Colors.black,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            alignment: Alignment.center,
            child: widgetVideo,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 30),
                onPressed: () => setState(() => showScreenShareFull = true),
                tooltip: "Full Screen",
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Row(
              children: [
                const Icon(Icons.screen_share, size: 18, color: Colors.greenAccent),
                const SizedBox(width: 6),
                Text(
                  '${presenter.displayName} is sharing',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSpeaker() {
    setState(() => speakerOn = !speakerOn);
  }

  Widget _buildHandleLine() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 60,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (displayName == "User" && ApiService.currentUserId != null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showScreenShareFull && presenterId != null) {
      return _buildScreenShareView(full: true);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _room.leave();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Video Call',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 21,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
          elevation: 1.5,
          backgroundColor: Color(0xFF6C63FF),
          centerTitle: true,
          automaticallyImplyLeading: false, // <------- Removes back arrow
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // User's Name at the top
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle, color: Colors.deepPurple, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.deepPurple,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (presenterId != null) _buildScreenShareView(),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.13),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 290,
                    ),
                    itemBuilder: (context, index) {
                      return ParticipantTile(
                        key: Key(participants.values.elementAt(index).id),
                        participant: participants.values.elementAt(index),
                      );
                    },
                    itemCount: participants.length,
                  ),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: controlsVisible
                    ? Column(
                  key: const ValueKey('controls'),
                  children: [
                    _buildMeetingControls(),
                  ],
                )
                    : GestureDetector(
                  key: const ValueKey('handle'),
                  onTap: () => setState(() => controlsVisible = true),
                  child: _buildHandleLine(),
                ),
              ),
              if (controlsVisible)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => controlsVisible = false),
                  child: Container(height: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingControls() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 3),
      child: Card(
        elevation: 8,
        color: Colors.deepPurple[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleButton(
                icon: Icons.mic,
                isOff: !micEnabled,
                onPressed: () {
                  micEnabled ? _room.muteMic() : _room.unmuteMic();
                  setState(() => micEnabled = !micEnabled);
                },
                color: Colors.deepPurple,
              ),
              _circleButton(
                icon: Icons.videocam,
                isOff: !camEnabled,
                onPressed: () {
                  camEnabled ? _room.disableCam() : _room.enableCam();
                  setState(() => camEnabled = !camEnabled);
                },
                color: Colors.purpleAccent,
              ),
              _circleButton(
                icon: Icons.screen_share,
                isOff: !isScreenSharing,
                onPressed: _shareScreen,
                color: Colors.greenAccent,
              ),
              _circleButton(
                icon: Icons.volume_up,
                isOff: !speakerOn,
                onPressed: _toggleSpeaker,
                color: Colors.orangeAccent,
              ),
              // REMOVED: More/Meeting Info button
              _circleButton(
                icon: Icons.call_end,
                onPressed: () {
                  _room.leave();
                },
                color: Colors.redAccent,
                iconColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isOff = false,
    Color iconColor = Colors.white,
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
            iconSize: 29,
            splashRadius: 28,
          ),
        ),
        if (isOff)
          Positioned(
            left: 10,
            right: 10,
            top: 21,
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