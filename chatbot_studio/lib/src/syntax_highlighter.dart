import 'package:flutter/material.dart';
import 'package:interpreter/interpreter.dart';

/// Unfortunately the Flutter Framework is still not bug-free on the web.
///
/// Therefore when trying to use this SyntaxHighlighter as a
/// TextEditingController in a TextField the cursor does not behave
/// correctly.
class SyntaxHighlighter extends TextEditingController {
  static TextSpan highlight(
    String sourceCode, {
    int beginStmtLine,
    int endStmtLine,
    int errorLine,
  }) {
    if (sourceCode == null || sourceCode.trim().isEmpty) {
      return TextSpan();
    }

    Lexer lexer = Lexer(sourceCode);
    final tokens = <Token>[];

    try {
      var token = lexer.next();
      while (token.type != TokenType.eof) {
        if (token.type != TokenType.newLine &&
            token.type != TokenType.indent &&
            token.type != TokenType.dedent) {
          tokens.add(token);
        }
        token = lexer.next();
      }
    } on LexerError {}

    // print(tokens.map((e) => '${e.line}:${e.col}').toList());

    int currTokenIndex = 0;
    Token currToken = tokens.isEmpty ? null : tokens.first;
    if (currToken == null) {
      return TextSpan();
    }

    var spans = <TextSpan>[];
    StringBuffer sb = StringBuffer();

    bool isToken = false;
    int line = 1, col = 0;
    var runes = sourceCode.runes.toList();
    for (int i = 0; i < runes.length; i++) {
      var char = String.fromCharCode(runes[i]);

      //* Highlight the line if it is currently being executed or if it
      //* contains an error.
      Color highlightColor;
      if (beginStmtLine != null && endStmtLine != null) {
        bool shouldHighlightLine = beginStmtLine <= line && line <= endStmtLine;
        if (shouldHighlightLine) {
          highlightColor = beginStmtLine != endStmtLine
              ? Colors.yellowAccent
              : Colors.greenAccent;
        } else if (errorLine != null && errorLine == line) {
          highlightColor = Colors.red;
        }
      }

      if (currToken == null) {
        sb.write(sourceCode.substring(i, sourceCode.length));
        String remainingStr = sb.toString();
        spans.add(
          TextSpan(
            text: remainingStr,
            style: _kDefaultStyle.copyWith(backgroundColor: highlightColor),
          ),
        );
        sb.clear();
        break;
      }

      if (isToken) {
        int tokenEndCol = currToken.col + currToken.rawValue.length;
        if (col == tokenEndCol) {
          String tokenStr = sb.toString();
          var style = _getStyleForToken(currToken).copyWith(
            backgroundColor: highlightColor,
          );
          spans.add(TextSpan(text: tokenStr, style: style));

          do {
            currTokenIndex++;
            if (currTokenIndex < tokens.length) {
              currToken = tokens[currTokenIndex];
            } else {
              currToken = null;
            }
          } while (currToken != null &&
              currToken.type == TokenType.newLine &&
              currToken.type == TokenType.indent &&
              currToken.type == TokenType.dedent);

          isToken = false;
          sb.clear();
        }
        sb.write(char);
      } else {
        if (currToken.line == line &&
            currToken.col == col &&
            currToken.type != TokenType.newLine &&
            currToken.type != TokenType.indent &&
            currToken.type != TokenType.dedent) {
          if (sb.isNotEmpty) {
            String nonTokenStr = sb.toString();
            spans.add(TextSpan(
                text: nonTokenStr,
                style:
                    _kDefaultStyle.copyWith(backgroundColor: highlightColor)));
          }

          isToken = true;
          sb.clear();
        }
        sb.write(char);
      }

      col++;
      if (char == '\n') {
        line++;
        col = 0;
      }
    }
    if (sb.isNotEmpty) {
      spans.add(TextSpan(text: sb.toString()));
    }

    return TextSpan(
      style: _kDefaultStyle,
      children: spans,
    );
  }

  SyntaxHighlighter() : super() {
    // addListener(() {
    //   final val = TextSelection.collapsed(offset: text.length);
    //   selection = val;
    // });
  }

  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    String sourceCode = this.text;
    if (sourceCode == null || sourceCode.trim().isEmpty) {
      return super.buildTextSpan(
        style: style,
        withComposing: withComposing,
      );
    }

    Lexer lexer = Lexer(sourceCode);
    final tokens = <Token>[];

    try {
      var token = lexer.next();
      while (token.type != TokenType.eof) {
        if (token.type != TokenType.comma &&
            token.type != TokenType.newLine &&
            token.type != TokenType.indent &&
            token.type != TokenType.dedent) {
          tokens.add(token);
        }
        token = lexer.next();
      }
    } on LexerError {}

    // print(tokens.map((e) => '${e.line}:${e.col}').toList());

    int currTokenIndex = 0;
    Token currToken = tokens.isEmpty ? null : tokens.first;
    if (currToken == null) {
      return super.buildTextSpan(
        style: style,
        withComposing: withComposing,
      );
    }

    var spans = <TextSpan>[];
    StringBuffer sb = StringBuffer();

    bool isToken = false;
    int line = 1, col = 0;
    var runes = sourceCode.runes.toList();
    for (int i = 0; i < runes.length; i++) {
      var char = String.fromCharCode(runes[i]);
      // print('$line:$col: $char');

      if (currToken == null) {
        sb.write(sourceCode.substring(i, sourceCode.length));
        String remainingStr = sb.toString();
        spans.add(TextSpan(text: remainingStr));
        sb.clear();
        break;
      }

      if (isToken) {
        int tokenEndCol = currToken.col + currToken.rawValue.length;
        if (col == tokenEndCol) {
          String tokenStr = sb.toString();
          var style = _getStyleForToken(currToken);
          spans.add(TextSpan(text: tokenStr, style: style));

          do {
            currTokenIndex++;
            if (currTokenIndex < tokens.length) {
              currToken = tokens[currTokenIndex];
            } else {
              currToken = null;
            }
          } while (currToken != null &&
              currToken.type == TokenType.newLine &&
              currToken.type == TokenType.indent &&
              currToken.type == TokenType.dedent);

          isToken = false;
          sb.clear();
        }
        sb.write(char);
      } else {
        if (currToken.line == line &&
            currToken.col == col &&
            currToken.type != TokenType.newLine &&
            currToken.type != TokenType.indent &&
            currToken.type != TokenType.dedent) {
          if (sb.isNotEmpty) {
            String nonTokenStr = sb.toString();
            spans.add(TextSpan(text: nonTokenStr));
          }

          isToken = true;
          sb.clear();
        }
        sb.write(char);
      }

      col++;
      if (char == '\n') {
        line++;
        col = 0;
      }
    }
    if (sb.isNotEmpty) {
      spans.add(TextSpan(text: sb.toString()));
    }

    // print(spans.map((e) => e.text).toList());

    return TextSpan(
      style: _kDefaultStyle,
      children: spans,
    );
  }
}

const _kDefaultStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'monospace',
  fontSize: 16.0,
);
const _kIntegerStyle = TextStyle(
  color: Colors.red,
  fontFamily: 'monospace',
  fontSize: 16.0,
);
const _kStringStyle = TextStyle(
  color: Colors.green,
  fontFamily: 'monospace',
  fontSize: 16.0,
);
const _kKeywordStyle = TextStyle(
  color: Colors.blue,
  fontFamily: 'monospace',
  fontSize: 16.0,
);

TextStyle _getStyleForToken(Token token) {
  return _kTokenStyles[token.type] ?? _kDefaultStyle;
}

const _kTokenStyles = {
  TokenType.integer: _kIntegerStyle,
  TokenType.string: _kStringStyle,
  TokenType.create: _kKeywordStyle,
  TokenType.sender: _kKeywordStyle,
  TokenType.counter: _kKeywordStyle,
  TokenType.set_: _kKeywordStyle,
  TokenType.delay: _kKeywordStyle,
  TokenType.dynamic_: _kKeywordStyle,
  TokenType.flow: _kKeywordStyle,
  TokenType.startFlow: _kKeywordStyle,
  TokenType.endFlow: _kKeywordStyle,
  TokenType.send: _kKeywordStyle,
  TokenType.text: _kKeywordStyle,
  TokenType.image: _kKeywordStyle,
  TokenType.audio: _kKeywordStyle,
  TokenType.event: _kKeywordStyle,
  TokenType.wait: _kKeywordStyle,
  TokenType.click: _kKeywordStyle,
  TokenType.action: _kKeywordStyle,
  TokenType.increment: _kKeywordStyle,
  TokenType.by: _kKeywordStyle,
  TokenType.decrement: _kKeywordStyle,
  TokenType.to: _kKeywordStyle,
  TokenType.addTag: _kKeywordStyle,
  TokenType.removeTag: _kKeywordStyle,
  TokenType.clearTags: _kKeywordStyle,
  TokenType.input: _kKeywordStyle,
  TokenType.singleChoice: _kKeywordStyle,
  TokenType.choice: _kKeywordStyle,
  TokenType.if_: _kKeywordStyle,
  TokenType.else_: _kKeywordStyle,
  TokenType.hasTag: _kKeywordStyle,
};

const _kKeywords = {
  TokenType.create,
  TokenType.sender,
  TokenType.counter,
  TokenType.set_,
  TokenType.delay,
  TokenType.dynamic_,
  TokenType.flow,
  TokenType.startFlow,
  TokenType.endFlow,
  TokenType.send,
  TokenType.text,
  TokenType.image,
  TokenType.audio,
  TokenType.event,
  TokenType.wait,
  TokenType.click,
  TokenType.action,
  TokenType.increment,
  TokenType.by,
  TokenType.decrement,
  TokenType.to,
  TokenType.addTag,
  TokenType.removeTag,
  TokenType.clearTags,
  TokenType.input,
  TokenType.singleChoice,
  TokenType.choice,
  TokenType.if_,
  TokenType.else_,
  TokenType.hasTag,
};
