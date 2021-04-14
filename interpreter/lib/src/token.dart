import 'dart:ui';

/// All occurring token types of the CCML domain-specific language.
enum TokenType {
  // Special Tokens
  none,
  eof,
  newLine,
  indent,
  dedent,
  // Literals
  integer,
  string,
  // Name
  name,
  // Keywords
  create,
  sender,
  counter,
  set_,
  delay,
  dynamic_,
  flow,
  startFlow,
  endFlow,
  send,
  text,
  image,
  audio,
  event,
  wait,
  click,
  action,
  increment,
  by,
  decrement,
  to,
  addTag,
  removeTag,
  clearTags,
  if_,
  else_,
  hasTag,
  // Keywords - Input
  input,
  singleChoice,
  choice,
  freeText,
  when,
  comma,
  respond,
  response,
  fallback,
  // Others
  assign,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
  equals,
}

/// The [Lexer] transforms the source code into a stream of [Token]s
/// that the [Parser] uses to build an abstract syntax tree (AST).
class Token {
  Token({
    this.type = TokenType.none,
    this.value,
    this.line = 1,
    this.col = 0,
  });

  /// The type of token.
  TokenType type;

  /// Contains the value of this token:
  /// - int: for INTEGER tokens (=value)
  /// - String: for STRING tokens (=value)
  /// - String: for NAME tokens (=name); NOT for KEYWORDS
  dynamic value;

  /// The line that the token appears in.
  /// The first line starts the index 1 (NOT 0).
  int line;

  /// The column that the token starts at.
  /// Together with the [line] it exactly specifies the location of the token
  /// in the program code.
  /// The first column starts at the index 0.
  int col;

  /// The raw string value that represents this token in the
  /// original string that the lexer has detected this token.
  ///
  /// Ignore. Used only for syntax highlighting.
  String rawValue;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return false;
    }
    return other is Token &&
        this.type == other.type &&
        this.value == other.value;
  }

  @override
  int get hashCode => hashList([this.type, this.value]);

  @override
  String toString() => 'Token [type=$type, line=$line, col=$col]';
}
