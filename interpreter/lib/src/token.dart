import 'dart:ui';

enum TokenType {
  // SPECIAL TOKENS
  none,
  eof,
  //
  newLine,
  indent,
  dedent,
  // LITERALS
  integer,
  string,
  //
  name,
  // KEYWORDS
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
  input,
  singleChoice,
  choice,
  if_,
  else_,
  hasTag,
  // OTHERS
  assign,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
  equals,
}

/// A Token represents a special todo.
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
