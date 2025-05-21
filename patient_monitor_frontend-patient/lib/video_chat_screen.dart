// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
// import 'video_service.dart';
// import 'webrtc_utils.dart';

// class VideoChatScreen extends StatefulWidget {
//   final String roomName;

//   const VideoChatScreen({Key? key, required this.roomName}) : super(key: key);

//   @override
//   _VideoChatScreenState createState() => _VideoChatScreenState();
// }

// class _VideoChatScreenState extends State<VideoChatScreen> {
//   late VideoService _videoService;
//   late RTCPeerConnection _peerConnection;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;
//   final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   bool _isConnected = false;
//   bool _isMuted = false;
//   bool _isVideoOff = false;

//   @override
//   void initState() {
//     super.initState();
//     initRenderers();
//     _initVideoChat();
//   }

//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     _peerConnection.close();
//     _videoService.dispose();
//     super.dispose();
//   }

//   Future<void> initRenderers() async {
//     await _localRenderer.initialize();
//     await _remoteRenderer.initialize();
//   }

//   Future<void> _initVideoChat() async {
//     // Initialize video service
//     _videoService = VideoService(serverUrl: 'http://localhost:3100');
//     _videoService.connect();

//     // Get local stream
//     _localStream = await WebRTCUtils.getLocalStream();
//     _localRenderer.srcObject = _localStream;

//     // Create peer connection
//     _peerConnection = await WebRTCUtils.createPeerConnection();

//     // Add local stream to peer connection
//     _localStream!.getTracks().forEach((track) {
//       _peerConnection.addTrack(track, _localStream!);
//     });

//     // Set up event listeners
//     _setupPeerConnectionListeners();
//     _setupSocketListeners();

//     // Join the room
//     _videoService.joinRoom(widget.roomName);
//   }

//   void _setupPeerConnectionListeners() {
//     _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
//       if (candidate.candidate != null) {
//         _videoService.sendCandidate(widget.roomName, candidate.toMap());
//       }
//     };

//     _peerConnection.onTrack = (RTCTrackEvent event) {
//       if (event.streams.isNotEmpty) {
//         setState(() {
//           _remoteRenderer.srcObject = event.streams[0];
//           _isConnected = true;
//         });
//       }
//     };

//     _peerConnection.onConnectionState = (RTCPeerConnectionState state) {
//       if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
//         setState(() {
//           _isConnected = false;
//         });
//       }
//     };
//   }

//   void _setupSocketListeners() {
//     _videoService.onParticipantReady(() {
//       _createAndSendOffer();
//     });

//     _videoService.onReceiveOffer((data) async {
//       final offer = data['offer'];
//       await _peerConnection.setRemoteDescription(
//         RTCSessionDescription(offer['sdp'], offer['type']),
//       );
      
//       final answer = await _peerConnection.createAnswer();
//       await _peerConnection.setLocalDescription(answer);
      
//       _videoService.sendAnswer(
//         widget.roomName,
//         {'sdp': answer.sdp, 'type': answer.type},
//       );
//     });

//     _videoService.onReceiveAnswer((data) async {
//       final answer = data['answer'];
//       await _peerConnection.setRemoteDescription(
//         RTCSessionDescription(answer['sdp'], answer['type']),
//       );
//     });

//     _videoService.onReceiveCandidate((data) async {
//       final candidate = data['candidate'];
//       if (candidate != null) {
//         await _peerConnection.addCandidate(
//           RTCIceCandidate(
//             candidate['candidate'],
//             candidate['sdpMid'],
//             candidate['sdpMLineIndex'],
//           ),
//         );
//       }
//     });

//     _videoService.onParticipantLeft(() {
//       setState(() {
//         _isConnected = false;
//         _remoteRenderer.srcObject = null;
//       });
//     });

//     _videoService.onTooManyParticipants(() {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Room Full'),
//           content: Text('This room already has 2 participants.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('OK'),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Future<void> _createAndSendOffer() async {
//     final offer = await _peerConnection.createOffer();
//     await _peerConnection.setLocalDescription(offer);
    
//     _videoService.sendOffer(
//       widget.roomName,
//       {'sdp': offer.sdp, 'type': offer.type},
//     );
//   }

//   void _toggleMute() {
//     if (_localStream != null) {
//       setState(() {
//         _isMuted = !_isMuted;
//       });
//       _localStream!.getAudioTracks().forEach((track) {
//         track.enabled = !_isMuted;
//       });
//     }
//   }

//   void _toggleVideo() {
//     if (_localStream != null) {
//       setState(() {
//         _isVideoOff = !_isVideoOff;
//       });
//       _localStream!.getVideoTracks().forEach((track) {
//         track.enabled = !_isVideoOff;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Video Chat - Room: ${widget.roomName}'),
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: _remoteStream != null
//                     ? RTCVideoView(_remoteRenderer)
//                     : Center(child: Text('Waiting for participant...')),
//               ),
//               if (_localStream != null)
//                 Container(
//                   width: 150,
//                   height: 200,
//                   alignment: Alignment.bottomRight,
//                   child: RTCVideoView(
//                     _localRenderer,
//                     mirror: true,
//                     objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                   ),
//                 ),
//             ],
//           ),
//           Positioned(
//             bottom: 20,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
//                   onPressed: _toggleMute,
//                   color: Colors.white,
//                   iconSize: 32,
//                 ),
//                 IconButton(
//                   icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
//                   onPressed: _toggleVideo,
//                   color: Colors.white,
//                   iconSize: 32,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }