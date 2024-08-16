import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class CustomChatInput extends StatelessWidget {
  final TextEditingController textController;
  final Function(types.PartialText) onSendPressed;

  CustomChatInput({
    required this.textController,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  onSendPressed(types.PartialText(text: text));
                  textController.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              final text = textController.text;
              if (text.isNotEmpty) {
                onSendPressed(types.PartialText(text: text));
                textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
