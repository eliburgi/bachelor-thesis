import 'package:chatbot_studio/src/syntax_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// used for state management
final codePanelKey = GlobalKey<CodePanelState>();

/// Represents a code-editing panel for .chat (CCML) code.
class CodePanel extends StatefulWidget {
  CodePanel({
    @required this.isRunningProgram,
  }) : super(key: codePanelKey);

  final bool isRunningProgram;

  @override
  CodePanelState createState() => CodePanelState();
}

class CodePanelState extends State<CodePanel> {
  /// Highlights the code lines from [from] to [to] to indicate
  /// that the source code is currently executed from to to.
  ///
  /// The lines will only be highlighted if the program is currently
  /// running.
  void highlightLines({
    @required int from,
    @required int to,
  }) {
    setState(() {
      _highlightedLineStart = from;
      _highlightedLineEnd = to;
      _highlightedErrorLine = -1;
    });
  }

  /// Marks the given line as having an error.
  void highlightError(int line) {
    setState(() {
      _highlightedErrorLine = line;
      _highlightedLineStart = -1;
      _highlightedLineEnd = -1;
    });
  }

  /// Gets the current source code from the text editor.
  String get sourceCode => _textEditingController.text;

  /// Set the editor´s source code to the provided [value].
  void setSourceCode(String value) {
    _textEditingController.text = value;
  }

  /// Un-focuses the code editor.
  void unfocus() {
    FocusScope.of(context).unfocus();

    //* CCML syntax requires a NEWLINE at the end of the program.
    //* If the user forgets to add that NEWLINE it is annoying for him/her.
    //* Thus we simply automatically check whenever the user is done typing
    //* if there is a NEWLINE at the end of the source code.
    //* If not, we simply add one.
    if (!sourceCode.endsWith('\n')) {
      setSourceCode('$sourceCode\n');
    }
  }

  /// Clears the source-code editor.
  void clear() {
    FocusScope.of(context).unfocus();
    _textEditingController.clear();
    highlightLines(from: null, to: null);
  }

  // Used for entering source code text.
  final _textEditingController = TextEditingController();
  var _textFieldFocusNode = FocusNode();

  // Used to highlight the currently executed statement (if any).
  var _highlightedLineStart = -1;
  var _highlightedLineEnd = -1;

  // Used to mark a line as containing an error.
  int _highlightedErrorLine = -1;

  @override
  void dispose() {
    _textEditingController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The user can no directly edit the source code when either the
    // program is currently running or an error is highlighted.
    bool allowEditing = !widget.isRunningProgram && _highlightedErrorLine < 1;
    bool isEditing = _textFieldFocusNode.hasFocus;

    Widget editor;
    if (allowEditing && isEditing) {
      // Build an editor that allows the user to freely edit the
      // source code.
      editor = RawKeyboardListener(
        focusNode: _textFieldFocusNode,
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
            // the user has pressed the TAB key
            // insert 2 whitespaces at the current cursor position
            var cursorSelection = _textEditingController.selection;
            var codePrefix = cursorSelection.textBefore(sourceCode);
            var codeSuffix = cursorSelection.textAfter(sourceCode);
            _textEditingController.value = TextEditingValue(
              text: '$codePrefix  $codeSuffix',
              selection: TextSelection.fromPosition(
                TextPosition(offset: cursorSelection.end + 2),
              ),
            );

            // without this code the text field would loose its focus
            // whenever the user presses TAB (default Flutter behavior)
            // this code therefore makes sure the cursor stays active
            // within the textfield even if the user pressed TAB
            FocusScope.of(context).requestFocus(_textFieldFocusNode);
          }
        },
        child: TextField(
          controller: _textEditingController,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16.0,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
          minLines: null, // needs to be null when expands is true
          maxLines: null, // needs to be null when expands is true
          expands: true,
        ),
      );
    } else {
      // Build an editor that highlights a running program´s code lines
      // as well as any errors that occured. This kind of editor is used
      // to highlight running programs but NOT to actually allow the user
      // to edit the source code.
      editor = RichText(
        text: SyntaxHighlighter.highlight(
          sourceCode,
          beginStmtLine: _highlightedLineStart,
          endStmtLine: _highlightedLineEnd,
          errorLine: _highlightedErrorLine,
        ),
      );

      // The editor is currently highlighting an errornous code line.
      // Whilst in this state, the user cannot directly edit the source
      // code. However, if the user clicks on the editor we interpret this
      // as "I want to edit the code again". Thus we de-highlight the
      // errornous line which in turn enables the editable text editor again.
      // if (_highlightedErrorLine > 0) {
      editor = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(_textFieldFocusNode);
          setState(() => _highlightedErrorLine = -1);
        },
        child: editor,
      );
      // }
    }

    // wrap the editor with this panel´s container
    return Container(
      constraints: BoxConstraints.expand(),
      padding: const EdgeInsets.only(left: 24.0, top: 12.0),
      color: Colors.white,
      child: editor,
    );
  }
}
