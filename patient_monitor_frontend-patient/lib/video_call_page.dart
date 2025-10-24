import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCVideoCallPage extends StatefulWidget {
  final String roomId;

  const WebRTCVideoCallPage({Key? key, required this.roomId}) : super(key: key);

  @override
  _WebRTCVideoCallPageState createState() => _WebRTCVideoCallPageState();
}

class _WebRTCVideoCallPageState extends State<WebRTCVideoCallPage> {
  late RTCPeerConnection _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;

  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _initWebRTC();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection.close();
    _localStream?.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _initWebRTC() async {
    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    // Create peer connection configuration
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    // Create peer connection
    _peerConnection = await createPeerConnection(configuration);

    // Set up event handlers
    _peerConnection.onIceConnectionState = (state) {
      print('ICE connection state: $state');
      setState(() {
        _isConnected = state == RTCIceConnectionState.RTCIceConnectionStateConnected;
      });
    };

    _peerConnection.onTrack = (event) {
      if (event.track.kind == 'video') {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    // Get local media
    await _getUserMedia();

    // For demo purposes - in real app, you'd connect via signaling server
    _createOffer();
  }

  Future<void> _getUserMedia() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': _isFrontCamera ? 'user' : 'environment'
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;

    // Add local stream to peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection.addTrack(track, _localStream!);
    });
  }

  Future<void> _createOffer() async {
    try {
      final offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);

      // In a real app, you'd send the offer to the other peer via signaling server
      // For demo, we'll simulate the connection
      _simulateAnswer();
    } catch (e) {
      print('Error creating offer: $e');
    }
  }

  Future<void> _simulateAnswer() async {
    // Simulate receiving an answer - in real app, this comes from signaling server
    try {
      final answer = await _peerConnection.createAnswer();
      await _peerConnection.setRemoteDescription(answer);
    } catch (e) {
      print('Error simulating answer: $e');
    }
  }

  Future<void> _toggleMute() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        // FIXED: Set enabled property directly (not async)
        audioTracks.first.enabled = !_isMuted;
        setState(() {
          _isMuted = !_isMuted;
        });
      }
    }
  }

  Future<void> _toggleVideo() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        // FIXED: Set enabled property directly (not async)
        videoTracks.first.enabled = !_isVideoEnabled;
        setState(() {
          _isVideoEnabled = !_isVideoEnabled;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      try {
        // Use the proper camera switching method
        await Helper.switchCamera(videoTrack);
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      } catch (e) {
        print('Error switching camera: $e');
        // Fallback: recreate stream with different camera
        await _switchCameraByRecreate();
      }
    }
  }

  Future<void> _switchCameraByRecreate() async {
    try {
      // Dispose current stream
      _localStream?.dispose();
      
      // Toggle camera facing mode
      _isFrontCamera = !_isFrontCamera;
      
      // Create new stream with switched camera
      await _getUserMedia();
      
      // Update local renderer
      _localRenderer.srcObject = _localStream;
      
      setState(() {});
    } catch (e) {
      print('Error recreating stream for camera switch: $e');
    }
  }

  void _endCall() {
    _peerConnection.close();
    _localStream?.dispose();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _videoView() {
    return Stack(
      children: [
        // Remote video (main view)
        RTCVideoView(
          _remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),

        // Local video (picture-in-picture)
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
              child: RTCVideoView(
                _localRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: _isFrontCamera,
              ),
            ),
          ),
        ),

        // Connection status
        if (!_isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Room: ${widget.roomId}',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _controlPanel() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute/Unmute
          CircleAvatar(
            backgroundColor: _isMuted ? Colors.red : Colors.white24,
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              ),
              onPressed: _toggleMute,
            ),
          ),

          // Switch Camera
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(Icons.cameraswitch, color: Colors.white),
              onPressed: _switchCamera,
            ),
          ),

          // End Call
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 30,
            child: IconButton(
              icon: Icon(Icons.call_end, color: Colors.white),
              onPressed: _endCall,
            ),
          ),

          // Video On/Off
          CircleAvatar(
            backgroundColor: _isVideoEnabled ? Colors.white24 : Colors.red,
            child: IconButton(
              icon: Icon(
                _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                color: Colors.white,
              ),
              onPressed: _toggleVideo,
            ),
          ),

          // Speaker (placeholder - would need audio management)
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(Icons.volume_up, color: Colors.white),
              onPressed: () {
                // Speaker toggle functionality would go here
              },
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

            // Top info bar
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        color: _isConnected ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isConnected ? 'Connected' : 'Connecting...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Room ID display
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Room: ${widget.roomId}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}