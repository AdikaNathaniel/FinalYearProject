import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

class PregChatBotPage extends StatefulWidget {
  @override
  _PregChatBotPageState createState() => _PregChatBotPageState();
}

class _PregChatBotPageState extends State<PregChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      messages.add({'sender': 'user', 'text': message});
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3100/api/v1/api/v1/chatbot/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': message}),
      );

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        String botResponse = jsonResponse['result']['response'] ?? '';
        setState(() {
          messages.add({'sender': 'bot', 'text': botResponse});
        });
      } else {
        setState(() {
          messages.add({
            'sender': 'bot',
            'text': 'Error: ${response.statusCode}. Please try again.'
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({'sender': 'bot', 'text': 'Failed to connect to server.'});
      });
    } finally {
      setState(() {
        isLoading = false;
        _controller.clear();
      });
    }
  }

  Widget buildMessage(Map<String, String> message) {
    final isUser = message['sender'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUser ? Icons.pregnant_woman : Icons.smart_toy,
            color: isUser ? Colors.pink : Colors.purple,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.pink[100] : Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: isUser
                  ? SelectableText(
                      message['text']!,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    )
                  : MarkdownBody(
                      data: message['text']!,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(fontSize: 14, color: Colors.black87),
                        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        h3: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        listBullet: TextStyle(color: Colors.black87),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: Center(
          child: const Text(
            'PregChatBot',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return buildMessage(messages[index]);
                  },
                ),
              ),
            ),
            SizedBox(height: 12),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(child: CircularProgressIndicator()),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    sendMessage(_controller.text);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.pink[300],
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
