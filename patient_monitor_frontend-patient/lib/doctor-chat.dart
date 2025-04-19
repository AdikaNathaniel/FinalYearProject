import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class DoctorChatPage extends StatefulWidget {
  final String doctorId;
  final String patientId;

  const DoctorChatPage({
    Key? key,
    this.doctorId = "doctor123",
    this.patientId = "patient456",
  }) : super(key: key);

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  IO.Socket? socket;
  List<Map<String, dynamic>> messages = [];
  TextEditingController messageController = TextEditingController();
  bool isConnected = false;
  String roomId = '';
  final ScrollController _scrollController = ScrollController();
  late Timer reconnectTimer;
  bool _isDisposed = false;
  final List<String> reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    await loadMessages();
    _setupSocketConnection();
    _startReconnectionTimer();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesString = prefs.getString('doctor_messages_${widget.patientId}');
    if (messagesString != null) {
      try {
        List<dynamic> messageList = json.decode(messagesString);
        if (mounted) {
          setState(() {
            messages = List<Map<String, dynamic>>.from(messageList);
            _sortMessages();
          });
        }
      } catch (e) {
        print('Error loading messages: $e');
      }
    }
  }

  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_messages_${widget.patientId}', json.encode(messages));
  }

  void _sortMessages() {
    messages.sort((a, b) {
      DateTime timeA = DateTime.parse(a['timestamp']);
      DateTime timeB = DateTime.parse(b['timestamp']);
      return timeA.compareTo(timeB);
    });
  }

  void _setupSocketConnection() {
    _cleanUpSocket();

    socket = IO.io(
      'http://localhost:3002',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .disableAutoConnect()
          .build(),
    );

    _setupSocketListeners();
    socket!.connect();
  }

  void _setupSocketListeners() {
    if (socket == null) return;

    socket!.onConnect((_) {
      if (_isDisposed) return;
      print('Connected to server');
      _registerUserAndStartConversation();
      if (mounted) {
        setState(() => isConnected = true);
      }
    });

    socket!.on('conversationStarted', (data) {
      if (_isDisposed) return;
      print('Conversation started: ${data['roomId']}');
      if (mounted) {
        setState(() => roomId = data['roomId']);
      }
      _getMessageHistory(data['roomId']);
    });

    socket!.on('messageHistory', (data) {
      if (_isDisposed || data['messages'] == null) return;
      print('Received message history');
      _handleMessageHistory(data['messages']);
    });

    socket!.on('newMessage', (message) {
      if (_isDisposed) return;
      print('New message received: $message');
      _handleNewMessage(message);
    });

    socket!.on('messagesRead', (data) {
      if (_isDisposed) return;
      print('Messages marked as read: ${data['messageIds']}');
      _markMessagesAsRead(data['messageIds']);
    });

    socket!.on('messageDeleted', (data) {
      if (_isDisposed) return;
      setState(() {
        if (data['deletedForEveryone']) {
          messages.removeWhere((msg) => msg['id'] == data['messageId']);
        } else {
          final message = messages.firstWhere((msg) => msg['id'] == data['messageId']);
          if (message != null) {
            if (message['deletedFor'] == null) {
              message['deletedFor'] = [];
            }
            message['deletedFor'].add(widget.doctorId);
          }
        }
        saveMessages();
      });
    });

    socket!.on('messageEdited', (data) {
      if (_isDisposed) return;
      setState(() {
        final message = messages.firstWhere((msg) => msg['id'] == data['messageId']);
        if (message != null) {
          message['content'] = data['newContent'];
          message['edited'] = true;
          message['editTimestamp'] = data['editTimestamp'];
          saveMessages();
        }
      });
    });

    socket!.on('messagePinned', (data) {
      if (_isDisposed) return;
      setState(() {
        final message = messages.firstWhere((msg) => msg['id'] == data['messageId']);
        if (message != null) {
          message['pinned'] = data['pinned'];
          message['pinnedBy'] = data['pinnedBy'];
          message['pinTimestamp'] = data['pinTimestamp'];
          saveMessages();
        }
      });
    });

    socket!.on('messageReaction', (data) {
      if (_isDisposed) return;
      setState(() {
        final message = messages.firstWhere((msg) => msg['id'] == data['messageId']);
        if (message != null) {
          message['reactions'] = Map<String, String>.from(data['reactions']);
          saveMessages();
        }
      });
    });

    socket!.on('user-joined', (data) => _showSystemMessage(data['message']));
    socket!.on('user-left', (data) => _showSystemMessage(data['message']));
    socket!.on('error', (data) => _showSystemMessage("Error: ${data['message']}"));

    socket!.onDisconnect((_) {
      if (_isDisposed) return;
      print('Disconnected from server');
      if (mounted) {
        setState(() => isConnected = false);
      }
    });

    socket!.onConnectError((error) {
      if (_isDisposed) return;
      print('Connection error: $error');
      if (mounted) {
        setState(() => isConnected = false);
      }
    });

    socket!.onReconnect((_) {
      if (_isDisposed) return;
      print('Reconnected to server');
      if (mounted) {
        setState(() => isConnected = true);
      }
      _registerUserAndStartConversation();
    });

    socket!.onReconnectAttempt((attemptNumber) {
      print('Reconnection attempt #$attemptNumber');
    });

    socket!.onReconnectFailed((_) {
      if (_isDisposed) return;
      print('Reconnection failed');
      if (mounted) {
        setState(() => isConnected = false);
      }
    });
  }

  void _registerUserAndStartConversation() {
    socket!.emit('register', {
      'userId': widget.doctorId,
      'role': 'doctor'
    });
    socket!.emit('startConversation', {
      'targetUserId': widget.patientId
    });
  }

  void _getMessageHistory(String roomId) {
    socket!.emit('getMessageHistory', {'roomId': roomId});
  }

  void _handleMessageHistory(List<dynamic> messageList) {
    if (!mounted) return;
    
    List<Map<String, dynamic>> newMessages = List<Map<String, dynamic>>.from(messageList);
    
    newMessages.addAll(messages.where((existingMsg) => 
      !newMessages.any((newMsg) => newMsg['id'] == existingMsg['id'])
    ));
    
    setState(() {
      messages = newMessages;
      _sortMessages();
    });
    
    saveMessages();
    _scrollToBottom();
  }

  void _handleNewMessage(dynamic message) {
    if (!mounted) return;
    
    setState(() {
      messages.add(Map<String, dynamic>.from(message));
      _sortMessages();
      saveMessages();
      if (message['senderId'] == widget.patientId) {
        socket!.emit('markAsRead', {
          'roomId': roomId,
          'messageIds': [message['id']]
        });
      }
    });
    
    _scrollToBottom();
  }

  void _markMessagesAsRead(List<dynamic> messageIds) {
    if (!mounted) return;
    
    setState(() {
      for (var message in messages) {
        if (messageIds.contains(message['id'])) {
          message['isRead'] = true;
        }
      }
      saveMessages();
    });
  }

  void deleteMessage(String messageId, bool deleteForEveryone) {
    if (socket != null && roomId.isNotEmpty) {
      socket!.emit('deleteMessage', {
        'roomId': roomId,
        'messageId': messageId,
        'deleteForEveryone': deleteForEveryone
      });
    }
  }

  void editMessage(String messageId, String newContent) {
    if (socket != null && roomId.isNotEmpty) {
      socket!.emit('editMessage', {
        'roomId': roomId,
        'messageId': messageId,
        'newContent': newContent
      });
    }
  }

  void pinMessage(String messageId, bool pin) {
    if (socket != null && roomId.isNotEmpty) {
      socket!.emit('pinMessage', {
        'roomId': roomId,
        'messageId': messageId,
        'pin': pin
      });
    }
  }

  void reactToMessage(String messageId, String reaction) {
    if (socket != null && roomId.isNotEmpty) {
      socket!.emit('reactToMessage', {
        'roomId': roomId,
        'messageId': messageId,
        'reaction': reaction
      });
    }
  }

  void _showEditDialog(String messageId, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Message'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              editMessage(messageId, controller.text);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: reactions.map((reaction) {
            return GestureDetector(
              onTap: () {
                reactToMessage(messageId, reaction);
                Navigator.pop(context);
              },
              child: Text(reaction, style: TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String messageId) {
    final isSelf = messages.firstWhere((msg) => msg['id'] == messageId)['senderId'] == widget.doctorId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text(isSelf 
          ? 'Delete for everyone or just for you?' 
          : 'This message will be deleted just for you'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          if (isSelf) TextButton(
            onPressed: () {
              deleteMessage(messageId, true);
              Navigator.pop(context);
            },
            child: Text('Delete for everyone'),
          ),
          TextButton(
            onPressed: () {
              deleteMessage(messageId, false);
              Navigator.pop(context);
            },
            child: Text(isSelf ? 'Delete for me' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
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

  void _startReconnectionTimer() {
    reconnectTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!isConnected && mounted && !_isDisposed) {
        print('Attempting to reconnect...');
        _setupSocketConnection();
      }
    });
  }

  void _showSystemMessage(String msg) {
    if (_isDisposed || !mounted) return;
    
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
      _sortMessages();
      saveMessages();
    });
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty || roomId.isEmpty || socket == null) return;

    final messageData = {
      'roomId': roomId,
      'content': messageController.text,
      'receiverId': widget.patientId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    socket!.emit('sendMessage', messageData);
    messageController.clear();
  }

  void _cleanUpSocket() {
    if (socket != null) {
      try {
        socket!.disconnect();
        socket!.dispose();
        socket = null;
      } catch (e) {
        print('Error during socket cleanup: $e');
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) return 'Today';
    if (messageDate == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    final msg = messages[index];
    final isSelf = msg['senderId'] == widget.doctorId;
    final isSystem = msg['senderId'] == 'system';
    
    // Check if message is deleted for current user
    final isDeletedForMe = (msg['deletedFor'] as List?)?.contains(widget.doctorId) ?? false;
    
    if (isDeletedForMe) {
      return Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'You deleted this message',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    // Date header
    Widget? dateHeader;
    if (index == 0 || 
        !_isSameDay(
          DateTime.parse(messages[index-1]['timestamp']), 
          DateTime.parse(msg['timestamp'])
        )) {
      dateHeader = Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDateHeader(DateTime.parse(msg['timestamp'])),
              style: TextStyle(fontSize: 12, color: Colors.teal.shade800),
            ),
          ),
        ),
      );
    }

    String formattedTime = DateFormat.jm().format(DateTime.parse(msg['timestamp']));

    // Reactions widget
    Widget? reactionsWidget;
    if (msg['reactions'] != null && (msg['reactions'] as Map).isNotEmpty) {
      reactionsWidget = Container(
        margin: EdgeInsets.only(top: 4),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 4,
          children: (msg['reactions'] as Map<String, dynamic>).entries.map((entry) {
            return GestureDetector(
              onTap: () => reactToMessage(msg['id'], entry.value),
              child: Text(entry.value, style: TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      children: [
        if (dateHeader != null) dateHeader,
        GestureDetector(
          onLongPress: () => _showMessageOptions(context, msg['id'], isSelf),
          child: Align(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg['pinned'] == true)
                    Container(
                      margin: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    msg['content'],
                    style: TextStyle(
                      fontSize: 16,
                      //  color: Colors.blue,
                       color: isSystem ? Colors.black54 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSystem ? Colors.black45 : Colors.black54,
                        ),
                      ),
                      if (msg['edited'] == true) ...[
                        SizedBox(width: 4),
                        Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isSelf) ...[
                        SizedBox(width: 4),
                        Icon(
                          msg['isRead'] ? Icons.done_all : Icons.done,
                          size: 14,
                          color: msg['isRead'] ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (reactionsWidget != null) reactionsWidget,
      ],
    );
  }

  void _showMessageOptions(BuildContext context, String messageId, bool isSelf) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Implement reply functionality
              },
            ),
            if (isSelf) ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                final message = messages.firstWhere((msg) => msg['id'] == messageId);
                _showEditDialog(messageId, message['content']);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(messageId);
              },
            ),
            ListTile(
              leading: Icon(Icons.push_pin),
              title: Text(messages.firstWhere((msg) => msg['id'] == messageId)['pinned'] == true 
                  ? 'Unpin' 
                  : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                final isPinned = messages.firstWhere((msg) => msg['id'] == messageId)['pinned'] == true;
                pinMessage(messageId, !isPinned);
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_emotions),
              title: Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(messageId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    reconnectTimer.cancel();
    _cleanUpSocket();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pregnant Woman Chat',
              style: TextStyle(
                color: Colors.white,
                ),
            ),
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
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Simple background color
              ),
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, size: 64, color: Colors.grey.shade300),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: _buildMessageItem,
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      // Show attachment options
                    },
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              minLines: 1,
                              maxLines: 5,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.emoji_emotions),
                            onPressed: () {
                              // Show emoji picker
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: isConnected ? sendMessage : null,
                    ),
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