import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/background_painter.dart';

class VideoCallPage extends StatefulWidget {
  final int uid;
  final String roomId; // Receiving the room ID from the Home Page

  VideoCallPage({
    Key? key,
    required this.uid,
    required this.roomId,
  }) : super(key: key);

  @override
  _VideoCallPageState createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late final RtcEngine _engine;
  bool _isJoined = false;
  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  Set<int> remoteUid = {};
  Map<int, bool> remoteVideoStatus = {};
  Future<void>? _initializeAgoraFuture;

  // Agora details
  final String appId = "4fc68fece37a45fbaa7745b94a66d100";
  final String token =
      "007eJxTYPhy+b/4vYVXJl76cna+p4lLOo/k0xXnFlSdFf/42M1gw92LCgwmaclmFmmpyanG5okmpmlJiYnm5iamSZYmiWZmKYYGBnV1nekNgYwMj1zCWBkZIBDE52YISS0uiS/LTEnNN2RgAACoMCYN";
  final String channelName = "Test_video1";

  @override
  void initState() {
    super.initState();
    _initializeAgoraFuture = _initAgora();
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

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
          debugPrint("remote user $rUid joined");
          setState(() {
            remoteUid.add(rUid);
            remoteVideoStatus[rUid] = true; // Video is initially on
          });
        },
        onUserOffline: (RtcConnection connection, int rUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $rUid left channel");
          setState(() {
            remoteUid.removeWhere((element) => element == rUid);
            remoteVideoStatus.remove(rUid);
          });
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int rUid,
            RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          setState(() {
            remoteVideoStatus[rUid] =
                state == RemoteVideoState.remoteVideoStateDecoding;
          });
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _joinMeeting();
  }

  Future<void> _joinMeeting() async {
    print("Joining channel: $channelName");
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(),
    );
  }

  void _toggleMicMute() {
    setState(() {
      _isAudioMuted = !_isAudioMuted;
    });
    _engine.muteLocalAudioStream(_isAudioMuted);
  }

  void _toggleCameraOff() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _engine.muteLocalVideoStream(_isVideoOff);
  }

  void _flipCamera() {
    _engine.switchCamera();
  }

  void _leaveCall() {
    setState(() {
      _isJoined = false;
    });
    _dispose();
    Navigator.pop(context);
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.grey[900],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.cameraswitch, color: Colors.white),
                title: Text('Flip Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _flipCamera();
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.white),
                title: Text('Share Room ID', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Room ID'),
                        content: Text(widget.roomId),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeAgoraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error initializing video call",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: BackgroundPainter(),
              ),
              Center(
                child: _isJoined ? _renderRemoteVideo() : Container(),
              ),
              Positioned(
                bottom: 120.0,
                right: 26.0,
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: Center(
                    child: _renderLocalVideo(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(
          _isAudioMuted ? Icons.mic_off : Icons.mic,
        ),
        onPressed: _toggleMicMute,
        iconSize: 32,
        color: Colors.white,
      ),
      Text(
        _isAudioMuted ? 'Unmute' : 'Mute',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    ],
  ),
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(
          _isVideoOff ? Icons.videocam_off : Icons.videocam,
        ),
        onPressed: _toggleCameraOff,
        iconSize: 32,
        color: Colors.white,
      ),
      Text(
        _isVideoOff ? 'Video : Off' : 'Video : On',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    ],
  ),
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.settings),
        onPressed: _showSettingsDialog,
        iconSize: 32,
        color: Colors.white,
      ),
      Text(
        'Settings',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    ],
  ),
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.exit_to_app),
        onPressed: _leaveCall,
        iconSize: 32,
        color: Colors.white,
      ),
      Text(
        'Leave',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    ],
  ),
],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _renderLocalVideo() {
    if (_isVideoOff) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          'Video Off',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    } else {
      return SizedBox(
        width: 120,
        height: 160,
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }
  }

  Widget _renderRemoteVideo() {
    if (remoteUid.isNotEmpty) {
      return Stack(
        children: remoteUid.map((rUid) {
          return remoteVideoStatus[rUid] == true
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: rUid),
                    connection: RtcConnection(channelId: channelName),
                  ),
                )
              : Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Text(
                    'Video Transmission Off',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
        }).toList(),
      );
    } else {
      return Center(
        child: Text(
          'Waiting for others to join...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
  }
}
