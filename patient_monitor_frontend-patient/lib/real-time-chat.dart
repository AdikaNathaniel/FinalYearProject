import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String userRole; // "doctor" or "patient"

  const ChatPage({Key? key, required this.userRole}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late IO.Socket socket;
  List<Map<String, String>> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    socket = IO.io(
      'http://localhost:3009', // Replace with your server IP if not localhost
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'user-role': widget.userRole})
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Connected as ${widget.userRole}');
    });

    socket.on('message', (data) {
      setState(() {
        messages.add({
          'role': data['role'] ?? 'unknown',
          'message': data['message'] ?? '',
          'time': data['time'] ?? '',
        });
      });
    });

    socket.on('user-joined', (data) {
      _showSystemMessage(data['message']);
    });

    socket.on('user-left', (data) {
      _showSystemMessage(data['message']);
    });
  }

  void _showSystemMessage(String msg) {
    setState(() {
      messages.add({
        'role': 'system',
        'message': msg,
        'time': DateFormat.jm().format(DateTime.now())
      });
    });
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    final now = DateTime.now();
    final formattedTime = DateFormat.jm().format(now);

    final messageData = {
      'role': widget.userRole,
      'message': messageController.text,
      'time': formattedTime,
    };

    socket.emit('newMessage', messageData);
    messageController.clear();
  }

  @override
  void dispose() {
    socket.dispose();
    messageController.dispose();
    super.dispose();
  }

  Widget buildMessage(Map<String, String> msg) {
    final isSelf = msg['role'] == widget.userRole;
    final isSystem = msg['role'] == 'system';

    return Align(
      alignment: isSystem
          ? Alignment.center
          : isSelf
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSystem
              ? Colors.grey.shade300
              : isSelf
                  ? Colors.green.shade100
                  : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg['message'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSystem ? Colors.black54 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg['time'] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.userRole == 'doctor' ? ' Doctor Chat' : 'Pregnant Woman Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.local_hospital),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: messages.reversed.map(buildMessage).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
