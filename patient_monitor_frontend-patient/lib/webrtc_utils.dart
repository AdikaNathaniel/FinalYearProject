import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCUtils {
  static Future<MediaStream> getLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  static Future<RTCPeerConnection> createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    RTCPeerConnection pc = await createPeerConnection();
    return pc;
  }
}