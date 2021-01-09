import 'package:chatbot_studio/src/main_scaffold.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(ChatbotStudioApplication());
}

class ChatbotStudioApplication extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot-Creator',
      home: MainScaffold(),
    );
  }
}
