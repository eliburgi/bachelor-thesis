import 'package:interpreter/src/token.dart';
import 'package:interpreter/src/util.dart';

/// Responsible for the lexogrphical analysis.
///
/// The lexo... analysis represents the first step of every compiler
/// or interpreter. The goal of this step is to transform the raw program
/// code (stream of characters) into a stream of tokens.
/// A token represents # todo
///
/// Other tasks of the Lexer include:
/// - ignoring white space or empty lines
class Lexer {
  static const NEWLINE = '\n';
  static const EOF = 'U+ffff'; // unspecified unicode point

  static const KEYWORDS = {
    'create': TokenType.create,
    'sender': TokenType.sender,
    'counter': TokenType.counter,
    'set': TokenType.set_,
    'delay': TokenType.delay,
    'dynamic': TokenType.dynamic_,
    'flow': TokenType.flow,
    'startFlow': TokenType.startFlow,
    'endFlow': TokenType.endFlow,
    'send': TokenType.send,
    'text': TokenType.text,
    'image': TokenType.image,
    'audio': TokenType.audio,
    'event': TokenType.event,
    'wait': TokenType.wait,
    'click': TokenType.click,
    'action': TokenType.action,
    'increment': TokenType.increment,
    'by': TokenType.by,
    'decrement': TokenType.decrement,
    'to': TokenType.to,
    'addTag': TokenType.addTag,
    'removeTag': TokenType.removeTag,
    'clearTags': TokenType.clearTags,
    'input': TokenType.input,
    'singleChoice': TokenType.singleChoice,
    'choice': TokenType.choice,
    'if': TokenType.if_,
    'else': TokenType.else_,
    'hasTag': TokenType.hasTag,
  };

  Lexer(
    this.program, {
    this.logPrinter,
  }) {
    // init state by reading the first character
    _readNextCharacter();
  }

  /// The .chat program code.
  /// This represents the stream of characters that is parsed and transformed
  /// into a stream of tokens.
  final String program;

  /// Gets the next token in the program code.
  Token next() {
    Token t = Token(line: _line, col: _col);

    if (_indentQueue.isNotEmpty) {
      _indentQueue.removeLast();
      t.type = TokenType.indent;
      _log('next - detected token: $t');
      return t;
    }

    if (_dedentQueue.isNotEmpty) {
      _dedentQueue.removeLast();
      t.type = TokenType.dedent;
      _log('next - detected token: $t');
      return t;
    }

    // NEWLINE
    // must precede the 'skip whitespaces' code because the newline is
    // considered to be a whitespace by the Util class too
    if (_currentChar == NEWLINE) {
      // we are at the beginning of a new line
      // try to detect an INDENT or DEDENT based on the difference in
      // indentation levels of the new line and previous line
      //
      // any detected indents or dedents get added to a queue and are returned
      // the next time calling next() -> see the two if statements above
      _checkForIndentsOrDedents();

      // skip all empty lines and whitespace until we are at a new valid char
      while (Util.isWhiteSpace(_currentChar)) {
        _log('next - skipping whitespace');
        _readNextCharacter();
      }

      t.type = TokenType.newLine;
      _log('next - detected token: $t');
      return t;
    }

    // skip whitespaces
    while (Util.isWhiteSpace(_currentChar)) {
      _log('next - skipping whitespace');
      _readNextCharacter();
    }

    // a token that starts with a digit must be an INTEGER
    if (Util.isDigit(_currentChar)) {
      _readInteger(t);
      _log('next - detected token: $t');
      return t;
    }

    // a token that starts with a ' must be a STRING
    if (_currentChar == '\'') {
      _readString(t);
      _log('next - detected token: $t');
      return t;
    }

    // a token that starts with a letter must be a NAME
    // this includes keywords such as: 'create', 'send', etc.
    if (Util.isLetter(_currentChar)) {
      _readName(t);
      _log('next - detected token: $t');
      return t;
    }

    if (_currentChar == '<') {
      _readNextCharacter();
      if (_currentChar == '=') {
        t.type = TokenType.lessThanEqual;
      } else {
        t.type = TokenType.lessThan;
      }
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }
    if (_currentChar == '>') {
      _readNextCharacter();
      if (_currentChar == '=') {
        t.type = TokenType.greaterThanEqual;
      } else {
        t.type = TokenType.greaterThan;
      }
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }
    if (_currentChar == '=') {
      _readNextCharacter();
      if (_currentChar == '=') {
        t.type = TokenType.equals;
      } else {
        t.type = TokenType.assign;
      }
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }

    // END OF FILE: the Lexer has now parsed the whole program
    if (_currentChar == EOF) {
      t.type = TokenType.eof;
      _log('next - detected token: $t');
      return t;
    }

    _error('ERROR - Unknown character: $_currentChar!');
    t.type = TokenType.none;
    _readNextCharacter();
    return t;
  }

  /// Reads an integer literal, starting at the current character
  /// in the program code.
  void _readInteger(Token t) {
    assert(Util.isDigit(_currentChar));

    String valueStr = '';
    while (Util.isDigit(_currentChar)) {
      valueStr = '$valueStr$_currentChar';
      _readNextCharacter();
    }

    t.type = TokenType.integer;
    t.value = int.parse(valueStr);
  }

  /// Reads a string literal, starting at the current character
  /// in the program code.
  void _readString(Token t) {
    assert(_currentChar == '\'');

    String value = '';
    _readNextCharacter();
    while (_currentChar != '\'') {
      value = '$value$_currentChar';
      _readNextCharacter();
    }
    _readNextCharacter();

    t.type = TokenType.string;
    t.value = value;
  }

  /// Reads a name, starting at the current character
  /// in the program code.
  void _readName(Token t) {
    assert(Util.isLetter(_currentChar));

    String name = '';
    while (Util.isLetter(_currentChar)) {
      name = '$name$_currentChar';
      _readNextCharacter();
    }

    if (KEYWORDS.containsKey(name)) {
      t.type = KEYWORDS[name];
    } else {
      // parameter name
      t.type = TokenType.name;
      t.value = name;
    }
  }

  void _checkForIndentsOrDedents() {
    assert(_currentChar == NEWLINE);

    // count the number of whitespaces at the start of the new line
    // this count is called indent-level
    // e.g. a line starting with 6 whitespaces has an indentLevel=6
    int newLineIndentLevel = 0;
    _readNextCharacter();
    while (_currentChar != EOF && Util.isWhiteSpace(_currentChar)) {
      if (_currentChar == NEWLINE) {
        // empty lines don´t count for indent/dedent computation
        newLineIndentLevel = 0;
      } else {
        newLineIndentLevel++;
      }
      _readNextCharacter();
    }
    int prevLineIndentLevel = _indentationLevelStack.last;
    int levelDifference = newLineIndentLevel - prevLineIndentLevel;

    const WHITESPACES_PER_INDENT = 2;
    if (levelDifference.abs() % WHITESPACES_PER_INDENT != 0) {
      // the number of white spaces is not a multiple of intents or dedents
      // e.g. if an indent is represented by 2 whitespaces
      // and the difference of the new line to the previous line is 3 whitespace
      // then this would equal one indent + one whitespace
      // but this is an invalid indent level because it is not a multiple of 2
      errors.add('Invalid indent or dedent!');
      _error('''Invalid Indent or Dedent at line $_line and col $_col: 
                prevLineIndentLevel=$prevLineIndentLevel
                newLineIndentLevel=$newLineIndentLevel
                whitespaces per indent = $WHITESPACES_PER_INDENT
            ''');
    }

    // the new line has the same indent level as the previous line
    // so we did not detect an indent or dedent
    if (levelDifference == 0) {
      return;
    }

    // the new line is less indented than the previous line (=dedent)
    // check how many dedents the new line has compared to the previous one
    if (levelDifference < 0) {
      int diff = levelDifference;
      while (diff <= -WHITESPACES_PER_INDENT) {
        diff += WHITESPACES_PER_INDENT;
        _dedentQueue.add(1);
      }
      while (_indentationLevelStack.last > newLineIndentLevel) {
        _indentationLevelStack.removeLast();
      }
      return;
    }

    // the new line is more indented than the previous line (=indent)
    // check how many indents the new line has compared to the previous one
    if (levelDifference > 0) {
      int diff = levelDifference;
      while (diff >= WHITESPACES_PER_INDENT) {
        diff -= WHITESPACES_PER_INDENT;
        _indentQueue.add(1);
      }
      _indentationLevelStack.add(newLineIndentLevel);
    }
  }

  /// The index of the current character in the [program].
  int _characterIndex = 0;

  /// The current character in the [program].
  String _currentChar;

  /// The current line the lexer is at.
  int _line = 1;

  /// The current column the lexer is at.
  int _col = 0;

  /// Keeps track of how often a tabulator has been used
  /// to indent the line at the start.
  ///
  /// Initially 0 tabulators have been used.
  ///
  /// Everytime a new line starts with a tabulator
  /// we push a new value onto the stack, which is the old value
  /// plus 1.
  ///
  /// We need this stack because we want to not only detect
  /// INDENTs but also DEDENTs.
  List<int> _indentationLevelStack = [0];
  List<int> _indentQueue = [];
  List<int> _dedentQueue = [];

  /// Reads the current character from the program and advances the [_line]
  /// and [_col] if needed.
  ///
  /// Returns [EOF] to indicate that there are no more tokens.
  void _readNextCharacter() {
    if (_characterIndex >= program.length) {
      _currentChar = EOF;
      return;
    }

    _currentChar = program[_characterIndex];
    _characterIndex++;
    _col++;

    if (_currentChar == NEWLINE) {
      _line++;
      _col = 0;
    }
  }

  List<String> errors = [];

  void _error(String message) {
    errors.add(message);
    // terminate lexer forcefully
    throw message;
  }

  LogPrinter logPrinter;

  void _log(String message) {
    if (logPrinter == null) return;
    logPrinter('Lexer - $message');
  }
}
