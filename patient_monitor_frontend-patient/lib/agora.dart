import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService extends ChangeNotifier {
  static const String appId = "1e83d054ca2a43dda969689a961ed0a8"; // From Agora Console

  Future<RtcEngine> initAgora() async {
    final engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(appId: appId));
    await engine.enableVideo();
    return engine;
  }

  Future<void> joinChannel(RtcEngine engine, String channelName) async {
    // For a production app, you would need to implement token server
    // For testing purposes, you can use a temporary token or null
    await engine.joinChannel(
      token: '', // Use an empty string instead of null
      channelId: channelName,
      uid: 0, // Auto-generates UID
      options: const ChannelMediaOptions(),
    );
  }
}