import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';

import 'agora.dart'; // Adjust path if needed

class CallPage extends StatefulWidget {
  final String channelName;

  const CallPage({Key? key, required this.channelName}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late RtcEngine _agoraEngine;
  bool _isJoined = false;
  int? _remoteUid;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _agoraEngine.leaveChannel();
    _agoraEngine.release();
    super.dispose();
  }

  Future<void> _initAgora() async {
    final agoraService = Provider.of<AgoraService>(context, listen: false);
    _agoraEngine = await agoraService.initAgora();
    
    _agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (connection, uid, elapsed) {
          setState(() {
            _remoteUid = uid;
          });
        },
        onUserOffline: (connection, uid, reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
    
    await agoraService.joinChannel(_agoraEngine, widget.channelName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Call")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_isJoined)
                  AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _agoraEngine,
                      canvas: const VideoCanvas(uid: 0), // Local view
                    ),
                  ),
                if (_remoteUid != null)
                  Positioned(
                    top: 20,
                    right: 20,
                    width: 120,
                    height: 150,
                    child: AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _agoraEngine,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: widget.channelName),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ElevatedButton(
              onPressed: () {
                _agoraEngine.leaveChannel();
                Navigator.pop(context);
              },
              child: const Text("End Call"),
            ),
          ),
        ],
      ),
    );
  }
}