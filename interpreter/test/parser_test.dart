import 'package:flutter_test/flutter_test.dart';
import 'package:interpreter/src/ast.dart';
import 'package:interpreter/src/lexer.dart';
import 'package:interpreter/src/parser.dart';

void main() {
  test('hello world', () {
    String program = '''
flow 'main'
  send text 'Hello World'
''';

    var lexer = Lexer(program);
    var parser = Parser(lexer);
    var tree = parser.parse();

    expect(
      tree,
      ProgramNode(
        mainFlow: FlowNode(
          name: 'main',
          statements: [
            SendStatementNode(
              messageType: SendMessageType.text,
              messageBody: 'Hello World',
            ),
          ],
        ),
      ),
    );
  });

  test('multiple send statements', () {
    String program = '''
flow 'main'
  send text 'Hello World'
  send image 'img.png'

  send audio 'audio.mp3'
''';

    var lexer = Lexer(program);
    var parser = Parser(lexer);
    var tree = parser.parse();

    expect(
      tree,
      ProgramNode(
        mainFlow: FlowNode(
          name: 'main',
          statements: [
            SendStatementNode(
              messageType: SendMessageType.text,
              messageBody: 'Hello World',
            ),
            SendStatementNode(
              messageType: SendMessageType.image,
              messageBody: 'img.png',
            ),
            SendStatementNode(
              messageType: SendMessageType.audio,
              messageBody: 'audio.mp3',
            ),
          ],
        ),
      ),
    );
  });

  test('with params', () {
    String program = '''
create sender 'AB'
  authorId = '#1'
flow 'main'
  send event 'start-task'
    payload = 123
''';

    var lexer = Lexer(program);
    var parser = Parser(lexer);
    var tree = parser.parse();

    expect(
      tree,
      ProgramNode(
        declarations: [
          CreateStatementNode(
            entityType: EntityType.sender,
            entityName: 'AB',
            params: {'authorId': '#1'},
          ),
        ],
        mainFlow: FlowNode(
          name: 'main',
          statements: [
            SendStatementNode(
              messageType: SendMessageType.event,
              messageBody: 'start-task',
              params: {'payload': 123},
            ),
            SendStatementNode(
              messageType: SendMessageType.text,
              messageBody: 'a',
            ),
          ],
        ),
      ),
    );
  });
}
