import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PregnantChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> availableDoctors;

  const PregnantChatPage({
    Key? key,
    required this.userId,
    required this.userName,
    required this.availableDoctors,
  }) : super(key: key);

  @override
  _PregnantChatPageState createState() => _PregnantChatPageState();
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String roomId;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.roomId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      roomId: json['roomId'] ?? '',
    );
  }
}

class _PregnantChatPageState extends State<PregnantChatPage> {
  late IO.Socket _socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  String _currentRoomId = '';
  String _currentDoctorId = '';
  String _currentDoctorName = '';
  bool _isTyping = false;
  String _typingUserId = '';
  bool _isConnecting = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    try {
      _socket = IO.io(
        'https://patient-monitor-backend-patient.fly.dev',
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setTimeout(30000)
          .enableAutoConnect()
          .build(),
      );

      _socket.onConnect((_) {
        print('✅ Connected to chat server');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConnected = true;
          });
        }
        
        _socket.emit('register', {
          'userId': widget.userId,
          'role': 'patient',
        });
      });

      _socket.onDisconnect((_) {
        print('❌ Disconnected from chat server');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConnected = false;
          });
        }
        _showSnackBar('Disconnected from server');
      });

      _socket.onError((error) {
        print('💥 Socket error: $error');
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
        }
        _showSnackBar('Connection error: $error');
      });

      _socket.on('newMessage', (data) {
        print('📨 New message received: $data');
        if (mounted && data['roomId'] == _currentRoomId) {
          setState(() {
            _messages.add(Message.fromJson(data));
            _scrollToBottom();
          });
        }
      });

      _socket.on('messageHistory', (data) {
        print('📚 Message history received: ${data['messages']?.length} messages');
        if (mounted) {
          setState(() {
            _messages = (data['messages'] as List).map<Message>((msg) => Message.fromJson(msg)).toList();
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _scrollToBottom();
          });
        }
      });

      _socket.on('conversationStarted', (data) {
        print('💬 Conversation started: ${data['roomId']}');
        if (mounted) {
          setState(() {
            _currentRoomId = data['roomId'];
          });
        }
      });

      _socket.on('userTyping', (data) {
        if (mounted) {
          setState(() {
            _isTyping = data['isTyping'];
            _typingUserId = data['userId'];
          });
        }
      });

      _socket.on('error', (data) {
        print('❌ Server error: $data');
        _showSnackBar(data['message'] ?? 'Unknown error');
      });

    } catch (e) {
      print('💥 Failed to connect: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
      _showSnackBar('Failed to connect: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startChatWithDoctor(String doctorId, String doctorName) {
    if (!_isConnected) {
      _showSnackBar('Not connected to server');
      return;
    }

    setState(() {
      _currentDoctorId = doctorId;
      _currentDoctorName = doctorName;
      _messages.clear();
    });
    
    _socket.emit('startConversation', {
      'targetUserId': doctorId,
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentRoomId.isEmpty) return;
    if (!_isConnected) {
      _showSnackBar('Not connected to server');
      return;
    }

    final message = _messageController.text.trim();
    _socket.emit('sendMessage', {
      'roomId': _currentRoomId,
      'content': message,
      'receiverId': _currentDoctorId,
    });
    
    setState(() {
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.userId,
        receiverId: _currentDoctorId,
        content: message,
        timestamp: DateTime.now(),
        isRead: false,
        roomId: _currentRoomId,
      ));
      _messageController.clear();
      _scrollToBottom();
    });
  }

  void _typing(bool isTyping) {
    if (!_isConnected || _currentRoomId.isEmpty) return;
    _socket.emit('typing', {
      'roomId': _currentRoomId,
      'isTyping': isTyping,
    });
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == widget.userId;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('D', style: TextStyle(color: Colors.white)),
              radius: 16,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text('P', style: TextStyle(color: Colors.white)),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    if (widget.availableDoctors.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No doctors available at the moment',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.availableDoctors.length,
        itemBuilder: (context, index) {
          final doctor = widget.availableDoctors[index];
          return GestureDetector(
            onTap: () => _startChatWithDoctor(
              doctor['id'] ?? doctor['_id'] ?? 'unknown',
              doctor['name'] ?? 'Doctor',
            ),
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentDoctorId == doctor['id'] ? Colors.blue[100] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentDoctorId == doctor['id'] ? Colors.blue : Colors.blue[200]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      doctor['name']?.substring(0, 1) ?? 'D',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(doctor['name'] ?? 'Doctor', style: TextStyle(fontSize: 12)),
                  Text(
                    doctor['specialization'] ?? 'General',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    String statusText;
    
    if (_isConnecting) {
      statusColor = Colors.orange;
      statusText = 'Connecting...';
    } else if (_isConnected) {
      statusColor = Colors.green;
      statusText = 'Connected';
    } else {
      statusColor = Colors.red;
      statusText = 'Disconnected';
    }

    return Container(
      padding: EdgeInsets.all(8),
      color: statusColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.circle,
            color: statusColor,
            size: 12,
          ),
          SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(color: statusColor),
          ),
          if (_isConnecting) ...[
            SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.all(8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text('D', style: TextStyle(color: Colors.white)),
            radius: 16,
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Dr. $_currentDoctorName is typing'),
                SizedBox(width: 8),
                Row(
                  children: [
                    _buildTypingDot(0),
                    SizedBox(width: 2),
                    _buildTypingDot(1),
                    SizedBox(width: 2),
                    _buildTypingDot(2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 6,
      height: 6,
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.grey[600]!,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentDoctorId.isEmpty
            ? Text('Chat with Doctors')
            : Text('Dr. $_currentDoctorName'),
        backgroundColor: Colors.pink[100],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDoctorList(),
          _buildConnectionStatus(),
          
          Expanded(
            child: _currentRoomId.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a doctor to start chatting',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isTyping && index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                      ),
                      
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(0, -2),
                              blurRadius: 4,
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onChanged: (text) {
                                  _typing(text.isNotEmpty);
                                },
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}