import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// used for state management
final codePanelKey = GlobalKey<CodePanelState>();

/// Represents a code-editing panel.
///
/// It allows the user to enter .chat code.
class CodePanel extends StatefulWidget {
  CodePanel({
    @required this.isRunningProgram,
  }) : super(key: codePanelKey);

  final bool isRunningProgram;

  @override
  CodePanelState createState() => CodePanelState();
}

class CodePanelState extends State<CodePanel> {
  /// Highlights the code lines from [from] to [to].
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

  /// Get the program code from the text editor.
  String get programCode => _textEditingController.text;

  /// Set the program code in the text editor.
  void setProgramCode(String value) {
    _textEditingController.text = value;
  }

  final _textEditingController = TextEditingController(text: '');
  var _textFieldFocusNode = FocusNode();

  var _highlightedLineStart = -1;
  var _highlightedLineEnd = -1;
  int _highlightedErrorLine = -1;

  List<String> get _programLines {
    var lines = programCode.split('\n');
    return lines;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var programLines = _programLines;

    Widget editor = Container(
      constraints: BoxConstraints.expand(),
      color: Colors.white,
      child: widget.isRunningProgram || _highlightedErrorLine > 0
          ? RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.subtitle1,
                children: List.generate(
                  programLines.length,
                  (lineIndex) {
                    int lineNr = lineIndex + 1;
                    bool highlightLine = _highlightedLineStart <= lineNr &&
                        lineNr <= _highlightedLineEnd;

                    if (highlightLine) {
                      var color = _highlightedLineStart != _highlightedLineEnd
                          ? Colors.yellowAccent
                          : Colors.greenAccent;
                      return TextSpan(
                        text: '${programLines[lineIndex]}\n',
                        style: Theme.of(context).textTheme.subtitle1.copyWith(
                              backgroundColor: color,
                            ),
                      );
                    }

                    bool highlightError = _highlightedErrorLine == lineNr;
                    if (highlightError) {
                      return TextSpan(
                        text: '${programLines[lineIndex]}\n',
                        style: Theme.of(context).textTheme.subtitle1.copyWith(
                              backgroundColor: Colors.redAccent,
                            ),
                      );
                    }

                    return TextSpan(
                      text: '${programLines[lineIndex]}\n',
                    );
                  },
                ),
              ),
            )
          : RawKeyboardListener(
              focusNode: _textFieldFocusNode,
              onKey: (event) {
                if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
                  // the user has pressed the TAB key
                  // insert 2 whitespaces at the current cursor position
                  var cursorSelection = _textEditingController.selection;
                  var codePrefix = cursorSelection.textBefore(programCode);
                  var codeSuffix = cursorSelection.textAfter(programCode);
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
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
                minLines: null, // needs to be null when expands is true
                maxLines: null, // needs to be null when expands is true
                expands: true,
              ),
            ),
    );

    if (_highlightedErrorLine > 0) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // start editing program again after an error has occurred
          setState(() {
            _highlightedErrorLine = -1;
          });
        },
        child: editor,
      );
    }

    return editor;
  }
}
