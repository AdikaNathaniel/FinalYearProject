import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final String appId;
  final String token;

  const VideoCallPage({
    Key? key,
    required this.channelName,
    required this.appId,
    required this.token,
  }) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final RtcEngine _engine;
  List<int> remoteUids = [];
  bool isJoined = false;
  bool switchCamera = true;
  bool isMuted = false;
  bool isVideoEnabled = true;
  bool isSpeakerEnabled = true;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> _initEngine() async {
    // Request microphone and camera permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC engine instance
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: widget.appId,
    ));

    // Register event handlers
    _registerEventHandlers();

    // Enable video
    await _engine.enableVideo();

    // Set up video encoding configuration
    await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 640, height: 360),
      frameRate: 15,
      bitrate: 1130,
    ));

    // Join channel
    await _joinChannel();
  }

  void _registerEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Local user joined channel: ${connection.channelId}');
          setState(() {
            isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user joined: $remoteUid');
          setState(() {
            remoteUids.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint('Remote user left: $remoteUid');
          setState(() {
            remoteUids.remove(remoteUid);
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint('Left channel');
          setState(() {
            remoteUids.clear();
            isJoined = false;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Error: $err, $msg');
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          debugPrint('Connection state changed: $state');
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    try {
      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      debugPrint('Error joining channel: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join call: $e')),
        );
      }
    }
  }

  Future<void> _leaveChannel() async {
    try {
      await _engine.leaveChannel();
      setState(() {
        remoteUids.clear();
        isJoined = false;
      });
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _engine.switchCamera();
      setState(() {
        switchCamera = !switchCamera;
      });
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _engine.muteLocalAudioStream(!isMuted);
      setState(() {
        isMuted = !isMuted;
      });
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      await _engine.muteLocalVideoStream(!isVideoEnabled);
      setState(() {
        isVideoEnabled = !isVideoEnabled;
      });
    } catch (e) {
      debugPrint('Error toggling video: $e');
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      await _engine.setEnableSpeakerphone(!isSpeakerEnabled);
      setState(() {
        isSpeakerEnabled = !isSpeakerEnabled;
      });
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
    }
  }

  // Widget methods for rendering video views
  Widget _renderLocalPreview() {
    if (!isJoined) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Joining video call...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _renderRemoteVideo(int uid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _videoView() {
    if (remoteUids.isEmpty) {
      return Stack(
        children: [
          _renderLocalPreview(),
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _renderLocalPreview(),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(child: _renderRemoteVideo(remoteUids[0])),
          Container(
            height: 120,
            margin: const EdgeInsets.all(8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _renderLocalPreview(),
                  ),
                ),
                ...remoteUids.sublist(1).map((uid) => Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _renderRemoteVideo(uid),
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _controlPanel() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
              onPressed: _toggleMute,
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
              onPressed: _switchCamera,
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 30,
            child: IconButton(
              icon: const Icon(Icons.call_end, color: Colors.white),
              onPressed: () {
                _leaveChannel();
                Navigator.pop(context);
              },
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(isVideoEnabled ? Icons.videocam : Icons.videocam_off, color: Colors.white),
              onPressed: _toggleVideo,
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(isSpeakerEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.white),
              onPressed: _toggleSpeaker,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _videoView(),
            _controlPanel(),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isJoined ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Channel: ${widget.channelName}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Users: ${remoteUids.length + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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