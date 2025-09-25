import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/participant.dart';
import 'package:videosdk/videosdk.dart';
import 'meetingcontrol.dart';
// Import your home content page
import 'package:skill_buddy_fyp/Screens/homecontent.dart';

class MeetingScreen extends StatefulWidget {
  final String meetingId;
  final String token;
  final String displayName;

  const MeetingScreen({
    super.key,
    required this.meetingId,
    required this.token,
    required this.displayName,
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
  bool _navigated = false; // Prevent double navigation

  @override
  void initState() {
    super.initState();
    _room = VideoSDK.createRoom(
      roomId: widget.meetingId,
      token: widget.token,
      displayName: widget.displayName,
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
        // Robust: always navigate to HomeScreenContent after leaving
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreenContent()),
              (Route<dynamic> route) => false,
        );
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

  Future<bool> _onWillPop() async {
    _room.leave();
    return false; // Prevent default pop, let Events.roomLeft handle navigation
  }

  void _shareScreen() async {
    try {
      if (!isScreenSharing) {
        await _room.enableScreenShare();
      } else {
        await _room.disableScreenShare();
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
                  '${presenter.displayName ?? "Presenter"} is sharing',
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: const [
          ListTile(
            leading: Icon(Icons.info, color: Colors.white),
            title: Text('Meeting Info', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    // Full screen screen share overlay
    if (showScreenShareFull && presenterId != null) {
      return _buildScreenShareView(full: true);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('VideoSDK Meeting'),
          elevation: 0,
          backgroundColor: Colors.grey[900],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  title: Text(
                    "Meeting ID: ${widget.meetingId}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  leading: const Icon(Icons.meeting_room, color: Colors.blueAccent),
                ),
              ),
              if (presenterId != null) _buildScreenShareView(),

              Expanded(
                child: GridView.builder(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 300,
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

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: controlsVisible
                    ? Column(
                  key: const ValueKey('controls'),
                  children: [
                    MeetingControls(
                      micEnabled: micEnabled,
                      camEnabled: camEnabled,
                      isScreenSharing: isScreenSharing,
                      speakerOn: speakerOn,
                      onToggleMicButtonPressed: () {
                        micEnabled ? _room.muteMic() : _room.unmuteMic();
                        setState(() => micEnabled = !micEnabled);
                      },
                      onToggleCameraButtonPressed: () {
                        camEnabled ? _room.disableCam() : _room.enableCam();
                        setState(() => camEnabled = !camEnabled);
                      },
                      onScreenSharePressed: _shareScreen,
                      onSpeakerTogglePressed: _toggleSpeaker,
                      onLeaveButtonPressed: () {
                        _room.leave();
                      },
                      onMorePressed: _showMoreOptions,
                    ),
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
}