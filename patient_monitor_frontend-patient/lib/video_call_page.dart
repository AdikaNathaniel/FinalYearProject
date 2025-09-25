import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  final TextEditingController _roomIdController = TextEditingController();
  String? _roomId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      setState(() => _isLoading = true);
      
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize renderers
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      
      // Get user media
      await _openUserMedia();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Initialization error: $e');
      setState(() => _isLoading = false);
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Initialization Error'),
            content: Text('Failed to initialize: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _openUserMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });
      
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = stream;
          _localStream = stream;
        });
      }
    } catch (e) {
      print('Error accessing media: $e');
      // Handle permission denied or no camera/mic
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera/Microphone Access'),
            content: const Text('Please allow access to camera and microphone to use video calling.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _createRoom() async {
    if (_isLoading) return;
    
    try {
      setState(() => _isLoading = true);
      
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc();
      _roomId = roomRef.id;

      final config = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      };

      _peerConnection = await createPeerConnection(config);
      
      // Add local tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Handle remote stream
      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          if (mounted) {
            setState(() {
              _remoteRenderer.srcObject = event.streams.first;
            });
          }
        }
      };

      // Create and set offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      await roomRef.set({'offer': offer.toMap()});

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate != null) {
          roomRef.collection('callerCandidates').add(candidate.toMap());
        }
      };

      // Listen for answer
      roomRef.snapshots().listen((snapshot) async {
        final data = snapshot.data();
        if (data != null && data['answer'] != null && _peerConnection != null) {
          final answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
          await _peerConnection!.setRemoteDescription(answer);
        }
      });

      // Listen for remote candidates
      roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        for (final docChange in snapshot.docChanges) {
          final data = docChange.doc.data();
          if (data != null && docChange.type == DocumentChangeType.added && _peerConnection != null) {
            _peerConnection?.addCandidate(
              RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
            );
          }
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error creating room: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create room: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty || _isLoading) return;
    
    try {
      setState(() => _isLoading = true);
      
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
      final roomSnapshot = await roomRef.get();
      
      if (!roomSnapshot.exists) {
        throw Exception('Room not found');
      }

      _roomId = roomId;

      final config = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      };

      _peerConnection = await createPeerConnection(config);
      
      // Add local tracks
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      // Handle remote stream
      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          if (mounted) {
            setState(() {
              _remoteRenderer.srcObject = event.streams.first;
            });
          }
        }
      };

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate != null) {
          roomRef.collection('calleeCandidates').add(candidate.toMap());
        }
      };

      // Set remote description from offer
      final offer = roomSnapshot.data()!['offer'];
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create and set answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      await roomRef.update({'answer': answer.toMap()});

      // Listen for caller candidates
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (final docChange in snapshot.docChanges) {
          final data = docChange.doc.data();
          if (data != null && docChange.type == DocumentChangeType.added && _peerConnection != null) {
            _peerConnection?.addCandidate(
              RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
            );
          }
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error joining room: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to join room: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _hangUp() async {
    try {
      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;
      
      // Clear remote renderer
      _remoteRenderer.srcObject = null;
      
      // Clear room ID
      _roomId = null;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error hanging up: $e');
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Call"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            )
          : Column(
              children: [
                // Video views
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _localStream != null
                        ? RTCVideoView(_localRenderer, mirror: true)
                        : const Center(
                            child: Text(
                              'Local Video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _remoteRenderer.srcObject != null
                        ? RTCVideoView(_remoteRenderer)
                        : const Center(
                            child: Text(
                              'Remote Video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ),
                
                // Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _roomId == null
                      ? Column(
                          children: [
                            TextField(
                              controller: _roomIdController,
                              decoration: const InputDecoration(
                                labelText: "Enter Room ID to Join",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _createRoom,
                                  icon: const Icon(Icons.add),
                                  label: const Text("Create Room"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _joinRoom,
                                  icon: const Icon(Icons.login),
                                  label: const Text("Join Room"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Connected to Room: $_roomId",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _hangUp,
                              icon: const Icon(Icons.call_end),
                              label: const Text("Hang Up"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(200, 45),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}