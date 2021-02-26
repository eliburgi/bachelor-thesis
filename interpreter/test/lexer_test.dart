import 'package:flutter_test/flutter_test.dart';
import 'package:interpreter/src/lexer.dart';
import 'package:interpreter/src/token.dart';

void main() {
  test('hello world', () {
    String program = '''
flow 'main'
  send text 'Hello World'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Hello World'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('hello world with missing indent', () {
    String program = '''
flow 'main'
send text 'Hello World'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Hello World'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.eof),
    ]);
  });

  test('hello world with too many indents', () {
    String program = '''
flow 'main'
    send text 'Hello World'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Hello World'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('invalid indent', () {
    String program = '''
flow 'main'
  send text 'valid indent (2 whitespace)'
   send text 'invalid indent (3 whitespace)'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    try {
      var token = lexer.next();
      while (token.type != TokenType.eof) {
        parsedTokens.add(token);
        token = lexer.next();
      }
      parsedTokens.add(token);
    } catch (error) {
      expect(lexer.errors.isNotEmpty, true);
    }
  });

  test('invalid dedent', () {
    String program = '''
flow 'main'
  send text 'valid indent'
 send text 'invalid dedent'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    try {
      var token = lexer.next();
      while (token.type != TokenType.eof) {
        parsedTokens.add(token);
        token = lexer.next();
      }
      parsedTokens.add(token);
    } catch (error) {
      expect(lexer.errors.isNotEmpty, true);
    }
  });

  test('send statements', () {
    String program = '''
flow 'main'
  send text 'Hello World'
  send image ''
  send audio 'url'
  send event 'eventId'
    data = 123
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Hello World'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.send),
      Token(type: TokenType.image),
      Token(type: TokenType.string, value: ''),
      Token(type: TokenType.newLine),
      Token(type: TokenType.send),
      Token(type: TokenType.audio),
      Token(type: TokenType.string, value: 'url'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.send),
      Token(type: TokenType.event),
      Token(type: TokenType.string, value: 'eventId'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.name, value: 'data'),
      Token(type: TokenType.assign),
      Token(type: TokenType.integer, value: 123),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('multiple flows', () {
    String program = '''
flow 'main'
  send text 'Hello World'

  send text 'a'
flow 'welcome'
  send text 'Welcome'



flow 'bye'
  send text 'Bye bye'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Hello World'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'a'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'welcome'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Welcome'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'bye'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Bye bye'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('many nested blocks 1', () {
    String program = '''
flow 'main'
  if hasTag 'a'
    if hasTag 'b'
      if hasTag 'c'
        send text 'abc'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.if_),
      Token(type: TokenType.hasTag),
      Token(type: TokenType.string, value: 'a'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.if_),
      Token(type: TokenType.hasTag),
      Token(type: TokenType.string, value: 'b'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.if_),
      Token(type: TokenType.hasTag),
      Token(type: TokenType.string, value: 'c'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'abc'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
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
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.create),
      Token(type: TokenType.sender),
      Token(type: TokenType.string, value: 'AB'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.name, value: 'authorId'),
      Token(type: TokenType.assign),
      Token(type: TokenType.string, value: '#1'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.event),
      Token(type: TokenType.string, value: 'start-task'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.name, value: 'payload'),
      Token(type: TokenType.assign),
      Token(type: TokenType.integer, value: 123),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('conditions (if/else)', () {
    String program = '''
create counter 'myCounter'

flow 'main'
  if counter 'myCounter' > 10
    send text 'Large'
  else 
    send text 'Small'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.create),
      Token(type: TokenType.counter),
      Token(type: TokenType.string, value: 'myCounter'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.if_),
      Token(type: TokenType.counter),
      Token(type: TokenType.string, value: 'myCounter'),
      Token(type: TokenType.greaterThan),
      Token(type: TokenType.integer, value: 10),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Large'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.else_),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Small'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('input freeText', () {
    String program = '''
flow 'main'
  input freeText
    when 'hi', 'hello', 'hey' respond 'greetings'
    response 'greetings'
      send text 'Hello human ...'
    fallback 
      send text 'I don´t understand this.'
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.input),
      Token(type: TokenType.freeText),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.when),
      Token(type: TokenType.string, value: 'hi'),
      Token(type: TokenType.comma),
      Token(type: TokenType.string, value: 'hello'),
      Token(type: TokenType.comma),
      Token(type: TokenType.string, value: 'hey'),
      Token(type: TokenType.respond),
      Token(type: TokenType.string, value: 'greetings'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.response),
      Token(type: TokenType.string, value: 'greetings'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'Hello human ...'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.fallback),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(type: TokenType.string, value: 'I don´t understand this.'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });

  test('action increment', () {
    String program = '''
set delay 1000
create counter 'myCounter'

flow 'main'
  send text 'Let´s have sun fun with actions! Shall we?'
  send text '1) You can increment the value of a counter'
  action increment 'myCounter' by 50
''';

    var lexer = Lexer(program);
    var parsedTokens = <Token>[];
    var token = lexer.next();
    while (token.type != TokenType.eof) {
      parsedTokens.add(token);
      token = lexer.next();
    }
    parsedTokens.add(token);

    expect(parsedTokens, [
      Token(type: TokenType.set_),
      Token(type: TokenType.delay),
      Token(type: TokenType.integer, value: 1000),
      Token(type: TokenType.newLine),
      Token(type: TokenType.create),
      Token(type: TokenType.counter),
      Token(type: TokenType.string, value: 'myCounter'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.flow),
      Token(type: TokenType.string, value: 'main'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.indent),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(
          type: TokenType.string,
          value: 'Let´s have sun fun with actions! Shall we?'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.send),
      Token(type: TokenType.text),
      Token(
          type: TokenType.string,
          value: '1) You can increment the value of a counter'),
      Token(type: TokenType.newLine),
      Token(type: TokenType.action),
      Token(type: TokenType.increment),
      Token(type: TokenType.string, value: 'myCounter'),
      Token(type: TokenType.by),
      Token(type: TokenType.integer, value: 50),
      Token(type: TokenType.newLine),
      Token(type: TokenType.dedent),
      Token(type: TokenType.eof),
    ]);
  });
}
