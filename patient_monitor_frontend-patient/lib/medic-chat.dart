// doctor_chat_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DoctorChatPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorChatPage({
    Key? key,
    required this.doctorId,
    required this.doctorName,
  }) : super(key: key);

  @override
  _DoctorChatPageState createState() => _DoctorChatPageState();
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

class ChatService {
  IO.Socket? _socket;
  bool _isConnected = false;

  Function(String, dynamic)? onNewMessage;
  Function(List<dynamic>)? onMessageHistory;
  Function(String)? onConversationStarted;
  Function(String, bool)? onUserTyping;
  Function(String)? onError;

  void connect(String userId, String role) {
    _socket = IO.io(
      'https://patient-monitor-backend-patient.fly.dev',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build(),
    );

    _socket!.onConnect((_) {
      print('Connected to chat server');
      _isConnected = true;
      
      _socket!.emit('register', {
        'userId': userId,
        'role': role,
      });
    });

    _socket!.onDisconnect((_) {
      print('Disconnected from chat server');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('Socket error: $error');
      onError?.call(error.toString());
    });

    _socket!.on('newMessage', (data) {
      onNewMessage?.call(data['roomId'], data);
    });

    _socket!.on('messageHistory', (data) {
      onMessageHistory?.call(data['messages']);
    });

    _socket!.on('conversationStarted', (data) {
      onConversationStarted?.call(data['roomId']);
    });

    _socket!.on('userTyping', (data) {
      onUserTyping?.call(data['userId'], data['isTyping']);
    });

    _socket!.on('error', (data) {
      onError?.call(data['message']);
    });
  }

  void startConversation(String targetUserId) {
    _socket!.emit('startConversation', {
      'targetUserId': targetUserId,
    });
  }

  void sendMessage(String roomId, String content, String receiverId) {
    _socket!.emit('sendMessage', {
      'roomId': roomId,
      'content': content,
      'receiverId': receiverId,
    });
  }

  void markAsRead(String roomId, List<String> messageIds) {
    _socket!.emit('markAsRead', {
      'roomId': roomId,
      'messageIds': messageIds,
    });
  }

  void typing(String roomId, bool isTyping) {
    _socket!.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  String _currentRoomId = '';
  String _currentPatientId = '';
  bool _isTyping = false;
  String _typingUserId = '';
  final List<String> _patients = ['patient1', 'patient2', 'patient3'];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _chatService.connect(widget.doctorId, 'doctor');
    
    _chatService.onNewMessage = (roomId, messageData) {
      if (mounted) {
        setState(() {
          _messages.add(Message.fromJson(messageData));
          _scrollToBottom();
        });
      }
    };

    _chatService.onMessageHistory = (messages) {
      if (mounted) {
        setState(() {
          _messages = messages.map<Message>((msg) => Message.fromJson(msg)).toList();
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _scrollToBottom();
        });
      }
    };

    _chatService.onConversationStarted = (roomId) {
      if (mounted) {
        setState(() {
          _currentRoomId = roomId;
        });
      }
    };

    _chatService.onUserTyping = (userId, isTyping) {
      if (mounted) {
        setState(() {
          _isTyping = isTyping;
          _typingUserId = userId;
        });
      }
    };

    _chatService.onError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    };
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

  void _startChatWithPatient(String patientId) {
    _chatService.startConversation(patientId);
    _currentPatientId = patientId;
    _messages.clear();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentRoomId.isEmpty) return;

    final message = _messageController.text.trim();
    _chatService.sendMessage(_currentRoomId, message, _currentPatientId);
    
    setState(() {
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.doctorId,
        receiverId: _currentPatientId,
        content: message,
        timestamp: DateTime.now(),
        isRead: false,
        roomId: _currentRoomId,
      ));
      _messageController.clear();
      _scrollToBottom();
    });
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == widget.doctorId;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Text('P', style: TextStyle(color: Colors.white)),
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
              backgroundColor: Colors.blue,
              child: Text('D', style: TextStyle(color: Colors.white)),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _startChatWithPatient(_patients[index]),
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('P', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 4),
                  Text('Patient ${index + 1}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Consultations'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildPatientList(),
          
          Container(
            padding: EdgeInsets.all(8),
            color: _chatService.isConnected ? Colors.green[50] : Colors.red[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _chatService.isConnected ? Icons.circle : Icons.circle_outlined,
                  color: _chatService.isConnected ? Colors.green : Colors.red,
                  size: 12,
                ),
                SizedBox(width: 8),
                Text(
                  _chatService.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _chatService.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _currentRoomId.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a patient to start consultation',
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
                              return Container(
                                margin: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Text('P', style: TextStyle(color: Colors.white)),
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
                                          Text('Typing'),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 20,
                                            height: 10,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                _buildTypingDot(0),
                                                _buildTypingDot(1),
                                                _buildTypingDot(2),
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
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (text) {
                                  _chatService.typing(_currentRoomId, text.isNotEmpty);
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
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}