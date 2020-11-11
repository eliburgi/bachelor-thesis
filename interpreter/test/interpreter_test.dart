import 'package:flutter_test/flutter_test.dart';

import 'package:interpreter/src/chatbot.dart';
import 'package:interpreter/src/interpreter.dart';

class MockedChatbot implements Chatbot {
  @override
  void clear() {}

  @override
  void sendMessage(Message message) {}

  @override
  Future<UserInputResponse> waitForInput(UserInput input) {
    return Future.sync(() => null);
  }

  @override
  void removeLastMessage() {}

  @override
  Future<void> waitForClick() {
    throw UnimplementedError();
  }

  @override
  Future<void> waitForEvent(String eventName) {
    throw UnimplementedError();
  }
}

void main() {
  test('hello world', () {
    String program = '''
flow 'main'
  send text 'Hello World'
''';

    var interpreter = Interpreter(MockedChatbot());
    interpreter.interpret(program);
  });
}
