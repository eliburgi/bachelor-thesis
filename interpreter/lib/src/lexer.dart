import 'package:interpreter/src/token.dart';
import 'package:interpreter/src/util.dart';

/// Responsible for the lexogrphical analysis.
///
/// The lexographic analysis represents the first step of every compiler
/// or interpreter. The goal of this step is to transform the raw script
/// code (stream of characters) into a stream of [Token]s.
///
/// Other tasks of the Lexer include:
/// * ignoring white space or empty lines
/// * indent & dedent detection
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
    'freeText': TokenType.freeText,
    'when': TokenType.when,
    'respond': TokenType.respond,
    'response': TokenType.response,
    'fallback': TokenType.fallback,
    'if': TokenType.if_,
    'else': TokenType.else_,
    'hasTag': TokenType.hasTag,
  };

  Lexer(this.script, {this.logPrinter}) {
    // init state by reading the first character
    _readNextCharacter();
  }

  /// The CCML script code.
  ///
  /// This represents the stream of characters that is parsed and transformed
  /// into a stream of tokens.
  final String script;

  /// Reads the next token from the [script].
  Token next() {
    if (_indentQueue.isNotEmpty) {
      _indentQueue.removeLast();
      Token t = Token(line: _line, col: _col);
      t.type = TokenType.indent;
      t.rawValue = '  ';
      _log('next - detected token: $t');
      return t;
    }

    if (_dedentQueue.isNotEmpty) {
      _dedentQueue.removeLast();
      Token t = Token(line: _line, col: _col);
      t.type = TokenType.dedent;
      t.rawValue = '';
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

      Token t = Token(line: _line, col: _col);
      t.type = TokenType.newLine;
      t.rawValue = '\n';
      _log('next - detected token: $t');
      return t;
    }

    // skip whitespaces
    while (Util.isWhiteSpace(_currentChar)) {
      //* Fixes a bug that is caused by trailing whitespaces in a line.
      //* Trailing whitespaces caused the lexer to get stuck into this
      //* loop and ignore NEWLINEs (they are detected as whitespace too).
      if (_currentChar == NEWLINE) {
        // handle the newline (see above)
        // important for indent/dedent detection
        return next();
      }
      _log('next - skipping whitespace');
      _readNextCharacter();
    }

    Token t = Token(line: _line, col: _col);

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
      _readNameOrKeyword(t);
      _log('next - detected token: $t');
      return t;
    }

    if (_currentChar == ',') {
      t.type = TokenType.comma;
      t.rawValue = ',';
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }
    if (_currentChar == '<') {
      _readNextCharacter();
      if (_currentChar == '=') {
        t.type = TokenType.lessThanEqual;
        t.rawValue = '<=';
      } else {
        t.type = TokenType.lessThan;
        t.rawValue = '<';
      }
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }
    if (_currentChar == '>') {
      _readNextCharacter();
      if (_currentChar == '=') {
        t.type = TokenType.greaterThanEqual;
        t.rawValue = '>=';
      } else {
        t.type = TokenType.greaterThan;
        t.rawValue = '>';
      }
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }
    if (_currentChar == '=') {
      _readNextCharacter();
      if (_currentChar == '=') {
        t.type = TokenType.equals;
        t.rawValue = '==';
      } else {
        t.type = TokenType.assign;
        t.rawValue = '=';
      }
      _readNextCharacter();
      _log('next - detected token: $t');
      return t;
    }

    // END OF FILE: the Lexer has now parsed the whole script
    if (_currentChar == EOF) {
      t.type = TokenType.eof;
      t.rawValue = '';
      _log('next - detected token: $t');
      return t;
    }

    _error('ERROR - Unknown character: $_currentChar!');
    t.type = TokenType.none;
    _readNextCharacter();
    return t;
  }

  /// Reads an integer literal, starting at the current character
  /// in the script code.
  void _readInteger(Token t) {
    assert(Util.isDigit(_currentChar));

    String valueStr = '';
    while (Util.isDigit(_currentChar)) {
      valueStr = '$valueStr$_currentChar';
      _readNextCharacter();
    }

    t.type = TokenType.integer;
    t.value = int.parse(valueStr);
    t.rawValue = valueStr;
  }

  /// Reads a string literal, starting at the current character
  /// in the script code.
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
    t.rawValue = '\'$value\'';
  }

  /// Reads a name, starting at the current character
  /// in the script code.
  void _readNameOrKeyword(Token t) {
    assert(Util.isLetter(_currentChar));

    String name = '';
    while (Util.isLetter(_currentChar)) {
      name = '$name$_currentChar';
      _readNextCharacter();
    }

    if (KEYWORDS.containsKey(name)) {
      t.type = KEYWORDS[name];
      t.rawValue = name;
    } else {
      // parameter name
      t.type = TokenType.name;
      t.value = name;
      t.rawValue = name;
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

  /// The index of the current character in the [script].
  int _characterIndex = 0;

  /// The current character in the [script].
  String _currentChar;

  /// The current line the lexer is at.
  int _line = 1;

  /// The current column the lexer is at.
  ///
  /// We are starting at -1 because of the initial call
  /// in the constructor (see constructor) increments it
  /// to its actual starting value which is 0.
  int _col = -1;

  //? TODO: Remove?
  String _lineStr;

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

  /// Reads the next character from the script and advances the [_line]
  /// and [_col] if needed.
  ///
  /// Returns [EOF] to indicate that there are no more tokens.
  void _readNextCharacter() {
    if (_characterIndex >= script.length) {
      _currentChar = EOF;
      return;
    }

    // This fixes a bug where the actual line and column number
    // would be incorrect for tokens at the start of a new line.
    // This has to do with the indent/dedent detection and the
    // _checkForIndentsOrDedents() function.
    if (_currentChar != NEWLINE) {
      _col++;
    }

    _currentChar = script[_characterIndex];
    _characterIndex++;

    _lineStr = '$_lineStr$_currentChar';

    if (_currentChar == NEWLINE) {
      _line++;
      _col = 0;
      _lineStr = '';
    }
  }

  List<String> errors = [];

  void _error(String message) {
    errors.add(message);
    // terminate lexer forcefully
    throw LexerError(message, _line, _col);
  }

  LogPrinter logPrinter;

  void _log(String message) {
    if (logPrinter == null) return;
    logPrinter('Lexer - $message');
  }
}

/// Represents errors that happen during the lexographic analysis
/// of a source code.
///
/// For example, the [Lexer] might detect an invalid character.
class LexerError {
  LexerError(this.message, this.line, this.col);

  final String message;
  final int line;
  final int col;

  @override
  String toString() => 'Lexer-Error in line $line: $message';
}
