// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class WebRTCUtils {
//   static Future<MediaStream> getLocalStream() async {
//     try {
//       final mediaConstraints = {
//         'audio': true,
//         'video': {
//           'width': {'ideal': 640},
//           'height': {'ideal': 480},
//           'frameRate': {'ideal': 30},
//           'facingMode': 'user',
//         }
//       };

//       final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
//       return stream;
//     } catch (e) {
//       print('Error getting local stream: $e');
//       rethrow;
//     }
//   }

//   static Future<RTCPeerConnection> createPeerConnection() async {
//     try {
//       final configuration = {
//         'iceServers': [
//           {'urls': 'stun:stun.l.google.com:19302'},
//           // You can add more STUN/TURN servers if needed
//         ]
//       };

//       final pc = await createPeerConnection(configuration, {});
//       return pc;
//     } catch (e) {
//       print('Error creating peer connection: $e');
//       rethrow;
//     }
//   }
// }