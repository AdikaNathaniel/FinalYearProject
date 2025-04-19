import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PregnantWomanChatPage extends StatefulWidget {
  final String patientId;
  final String doctorId;

  const PregnantWomanChatPage({
    Key? key,
    this.patientId = "patient456",
    this.doctorId = "doctor123",
  }) : super(key: key);

  @override
  State<PregnantWomanChatPage> createState() => _PregnantWomanChatPageState();
}

class _PregnantWomanChatPageState extends State<PregnantWomanChatPage> {
  late IO.Socket socket;
  List<Map<String, dynamic>> messages = [];
  TextEditingController messageController = TextEditingController();
  bool isConnected = false;
  bool isConnecting = true;
  String connectionError = '';
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
    final String? messagesString = prefs.getString('patient_messages_${widget.doctorId}');
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
    prefs.setString('patient_messages_${widget.doctorId}', json.encode(messages));
  }

  String getServerUrl() {
    if (kIsWeb) {
      return 'http://localhost:3002';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3002';
    } else if (Platform.isIOS) {
      return 'http://localhost:3002';
    } else {
      return 'http://localhost:3002';
    }
  }

  void connectToServer() {
    final String serverUrl = getServerUrl();
    print('Attempting to connect to server at: $serverUrl');

    setState(() {
      isConnecting = true;
      connectionError = '';
    });

    try {
      socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(3000)
            .build(),
      );

      socket.onConnect((_) {
        print('Connected to server at $serverUrl');
        socket.emit('register', {
          'userId': widget.patientId,
          'role': 'patient'
        });
        socket.emit('startConversation', {
          'targetUserId': widget.doctorId
        });
        setState(() {
          isConnected = true;
          isConnecting = false;
          connectionError = '';
        });
        _showSystemMessage("Connected to chat server successfully!");
      });

      socket.on('conversationStarted', (data) {
        print('Conversation started: ${data['roomId']}');
        setState(() {
          roomId = data['roomId'];
        });
        socket.emit('getMessageHistory', {
          'roomId': data['roomId']
        });
      });

      socket.on('messageHistory', (data) {
        print('Received message history');
        if (data['messages'] != null) {
          setState(() {
            messages = List<Map<String, dynamic>>.from(data['messages']);
            messages.sort((a, b) {
              DateTime timeA = DateTime.parse(a['timestamp']);
              DateTime timeB = DateTime.parse(b['timestamp']);
              return timeA.compareTo(timeB);
            });
          });
          saveMessages();
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
          if (message['senderId'] == widget.doctorId) {
            socket.emit('markAsRead', {
              'roomId': roomId,
              'messageIds': [message['id']]
            });
          }
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
        print('Socket error from server: ${data['message']}');
        _showSystemMessage("Error: ${data['message']}");
      });

      socket.onDisconnect((_) {
        print('Disconnected from server');
        setState(() {
          isConnected = false;
          isConnecting = false;
        });
        _showSystemMessage("Disconnected from chat server");
      });

      socket.onConnectError((error) {
        print('Connection error: $error');
        setState(() {
          isConnected = false;
          isConnecting = false;
          connectionError = 'Failed to connect: $error';
        });
        _showSystemMessage("Connection error: Cannot reach the chat server.");
      });

      socket.onReconnect((_) {
        print('Reconnected to server');
        setState(() {
          isConnecting = false;
          isConnected = true;
          connectionError = '';
        });
        _showSystemMessage("Reconnected to chat server");
      });

      // Connect the socket
      socket.connect();

    } catch (e) {
      print('Exception during socket setup: $e');
      setState(() {
        isConnecting = false;
        isConnected = false;
        connectionError = 'Socket initialization error: $e';
      });
      _showSystemMessage("Failed to initialize socket connection: $e");
    }
  }

  void _showSystemMessage(String msg) {
    final systemMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'system',
      'receiverId': 'all',
      'content': msg,
      'timestamp': DateTime.now().toUtc().toIso8601String(), // Store in UTC
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
      'receiverId': widget.doctorId,
      'timestamp': DateTime.now().toUtc().toIso8601String(), // Store in UTC
    };

    socket.emit('sendMessage', messageData);
    messageController.clear();
  }

  void retryConnection() {
    socket.disconnect();
    connectToServer();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String formatTimestamp(String timestampStr) {
    try {
      // Parse the UTC timestamp string into a DateTime object
      final DateTime utcTimestamp = DateTime.parse(timestampStr);
      
      // Convert to Ghana time zone (UTC+0)
      final DateTime ghanaTimestamp = utcTimestamp.toLocal(); // Adjust if needed

      // Format using local time zone
      final DateFormat formatter = DateFormat('h:mm a'); // 12-hour format with AM/PM
      return formatter.format(ghanaTimestamp);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Invalid time';
    }
  }

  Widget buildMessage(Map<String, dynamic> msg) {
    final isSelf = msg['senderId'] == widget.patientId;
    final isSystem = msg['senderId'] == 'system';
    
    // Format the timestamp using our new method
    final formattedTime = formatTimestamp(msg['timestamp']);

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
                  ? Colors.pink.shade100
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
            Text('Doctor Chat'),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected 
                      ? Colors.green 
                      : (isConnecting ? Colors.yellow : Colors.red),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected 
                    ? 'Online' 
                    : (isConnecting ? 'Connecting...' : 'Disconnected'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected 
                      ? Colors.greenAccent 
                      : (isConnecting ? Colors.yellow : Colors.red[300]),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.pink,
        actions: [
          if (!isConnected && !isConnecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: retryConnection,
              tooltip: 'Retry connection',
            ),
        ],
      ),
      body: Column(
        children: [
          if (connectionError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Text(
                connectionError,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: isConnecting
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(color: Colors.pink),
                              SizedBox(height: 16),
                              Text(
                                'Connecting to server...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No messages yet. Start the conversation!',
                                style: TextStyle(color: Colors.grey),
                              ),
                              if (!isConnected) 
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton(
                                    onPressed: retryConnection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink,
                                    ),
                                    child: const Text('Reconnect'),
                                  ),
                                ),
                            ],
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
                        hintText: isConnected ? "Type your message..." : "Connect to send messages...",
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
                      enabled: isConnected,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaterialButton(
                    onPressed: isConnected ? sendMessage : null,
                    shape: const CircleBorder(),
                    color: isConnected ? Colors.pink : Colors.grey,
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