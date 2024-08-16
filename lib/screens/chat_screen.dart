import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  final _aiUser = const types.User(
    id: 'vriddhi-ai',
    firstName: 'Vriddhi',
    // No need to set imageUrl since we'll load the avatar from assets
  );
  late GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _addWelcomeMessage();
  }

  void _initializeChat() {
    const apiKey = 'AIzaSyDSyXSQDDTlRc8q6VngIarQEnyBtyU1c2E'; // Replace with your actual API key
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _chat = _model.startChat();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = types.TextMessage(
      author: _aiUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: "Hello! I'm Vriddhi, your EcoYieldPro AI assistant. How can I help you with your farm today?",
    );
    _addMessage(welcomeMessage);
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // Show typing indicator
    setState(() {
      _messages.insert(0, types.CustomMessage(
        author: _aiUser,
        id: const Uuid().v4(),
        metadata: {'type': 'typing_indicator'},
      ));
    });

    try {
      final response = await _chat.sendMessage(Content.text(message.text));
      final responseText = response.text;

      // Remove typing indicator
      setState(() {
        _messages.removeAt(0);
      });

      if (responseText != null) {
        final aiMessage = types.TextMessage(
          author: _aiUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: responseText,
        );
        _addMessage(aiMessage);
      }
    } catch (e) {
      print('Error: $e');
      // Remove typing indicator
      setState(() {
        _messages.removeAt(0);
      });
      // Show error message
      _addMessage(types.TextMessage(
        author: _aiUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: "I'm sorry, I encountered an error. Please try again.",
      ));
    }
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advisory from Vriddhi AI'),
        backgroundColor: Colors.green,
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        theme: DefaultChatTheme(
          primaryColor: Colors.green,
          secondaryColor: Colors.green[100]!,
          backgroundColor: Colors.white,
          inputBackgroundColor: Colors.green[50]!,
          inputTextColor: Colors.black87,
          inputTextCursorColor: Colors.green,
          messageBorderRadius: 20,
          sendButtonIcon: Icon(Icons.send, color: Colors.black),
          sendingIcon: Icon(Icons.access_time, color: Colors.green),
          deliveredIcon: Icon(Icons.check, color: Colors.green),
          errorColor: Colors.red,
          userAvatarNameColors: [Colors.blue],
        ),
        customMessageBuilder: _customMessageBuilder,
      ),
    );
  }

  Widget _customMessageBuilder(types.CustomMessage message, {required int messageWidth}) {
    if (message.metadata?['type'] == 'typing_indicator') {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/chatbot.png'), // Load the image from assets
              radius: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Vriddhi is typing...',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return SizedBox(); // Return an empty SizedBox for unknown custom message types
  }
}
