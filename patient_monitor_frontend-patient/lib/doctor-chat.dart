import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DoctorChatPage extends StatefulWidget {
  // You can pass these through parameters or hardcode them
  final String doctorId;
  final String patientId;
  
  const DoctorChatPage({
    Key? key,
    this.doctorId = "doctor123", // Hardcoded default doctor ID
    this.patientId = "patient456", // Hardcoded default patient ID
  }) : super(key: key);

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  late IO.Socket socket;
  List<Map<String, dynamic>> messages = [];
  TextEditingController messageController = TextEditingController();
  bool isConnected = false;
  String roomId = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadMessages();
    connectToServer();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesString = prefs.getString('doctor_messages_${widget.patientId}');
    if (messagesString != null) {
      try {
        List<dynamic> messageList = json.decode(messagesString);
        setState(() {
          messages = List<Map<String, dynamic>>.from(messageList);
        });
      } catch (e) {
        print('Error loading messages: $e');
      }
    }
  }

  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('doctor_messages_${widget.patientId}', json.encode(messages));
  }

  void connectToServer() {
    socket = IO.io(
      'http://localhost:3009', // Replace with your server IP
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Connected to server');
      
      // IMPORTANT: Hardcoded registration as doctor
      socket.emit('register', {
        'userId': widget.doctorId,
        'role': 'doctor'
      });
      
      // Start conversation with patient
      socket.emit('startConversation', {
        'targetUserId': widget.patientId
      });
      
      setState(() {
        isConnected = true;
      });
    });

    socket.on('conversationStarted', (data) {
      print('Conversation started: ${data['roomId']}');
      setState(() {
        roomId = data['roomId'];
      });
      
      // Request message history
      socket.emit('getMessageHistory', {
        'roomId': data['roomId']
      });
    });
    
    socket.on('messageHistory', (data) {
      print('Received message history');
      if (data['messages'] != null) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
          
          // Sort messages by timestamp
          messages.sort((a, b) {
            DateTime timeA = DateTime.parse(a['timestamp']);
            DateTime timeB = DateTime.parse(b['timestamp']);
            return timeA.compareTo(timeB);
          });
        });
        
        saveMessages();
        
        // Scroll to bottom after messages load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    socket.on('newMessage', (message) {
      print('New message received: $message');
      setState(() {
        messages.add(Map<String, dynamic>.from(message));
        saveMessages();
        
        // Mark message as read if from patient
        if (message['senderId'] == widget.patientId) {
          socket.emit('markAsRead', {
            'roomId': roomId,
            'messageIds': [message['id']]
          });
        }
        
        // Scroll to bottom after new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    });

    socket.on('messagesRead', (data) {
      print('Messages marked as read: ${data['messageIds']}');
      setState(() {
        for (var message in messages) {
          if (data['messageIds'].contains(message['id'])) {
            message['isRead'] = true;
          }
        }
        saveMessages();
      });
    });

    socket.on('user-joined', (data) {
      _showSystemMessage(data['message']);
    });

    socket.on('user-left', (data) {
      _showSystemMessage(data['message']);
    });
    
    socket.on('error', (data) {
      _showSystemMessage("Error: ${data['message']}");
    });
    
    socket.onDisconnect((_) {
      print('Disconnected from server');
      setState(() {
        isConnected = false;
      });
    });
    
    socket.onConnectError((error) {
      print('Connection error: $error');
      setState(() {
        isConnected = false;
      });
    });
  }

  void _showSystemMessage(String msg) {
    final systemMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'system',
      'receiverId': 'all',
      'content': msg,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': true
    };
    
    setState(() {
      messages.add(systemMessage);
      saveMessages();
    });
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty || roomId.isEmpty) return;

    final messageData = {
      'roomId': roomId,
      'content': messageController.text,
      'receiverId': widget.patientId
    };

    socket.emit('sendMessage', messageData);
    messageController.clear();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget buildMessage(Map<String, dynamic> msg) {
    final isSelf = msg['senderId'] == widget.doctorId;
    final isSystem = msg['senderId'] == 'system';
    
    // Format the timestamp
    String formattedTime = '';
    try {
      final timestamp = DateTime.parse(msg['timestamp']);
      formattedTime = DateFormat.jm().format(timestamp);
    } catch (e) {
      formattedTime = 'Invalid time';
    }

    return Align(
      alignment: isSystem
          ? Alignment.center
          : isSelf
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSystem
              ? Colors.grey.shade300
              : isSelf
                  ? Colors.teal.shade100
                  : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSystem ? msg['content'] : msg['content'],
              style: TextStyle(
                fontSize: 16,
                color: isSystem ? Colors.black54 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg['isRead'] ? Icons.done_all : Icons.done,
                      size: 14,
                      color: msg['isRead'] ? Colors.blue : Colors.black45,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Chat (ID: ${widget.patientId})'),
            Text(
              isConnected ? 'Online' : 'Connecting...',
              style: TextStyle(
                fontSize: 12,
                color: isConnected ? Colors.greenAccent : Colors.grey,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => buildMessage(messages[index]),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaterialButton(
                    onPressed: isConnected ? sendMessage : null,
                    shape: const CircleBorder(),
                    color: Colors.teal,
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}