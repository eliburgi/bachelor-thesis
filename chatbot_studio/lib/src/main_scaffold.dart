import 'dart:convert';
import 'dart:js' as js;
import 'dart:html' as html;

import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:file_picker_web/file_picker_web.dart' as webPicker;

import 'package:flutter/material.dart';
import 'package:interpreter/interpreter.dart';

import 'chatbot_panel.dart';
import 'code_panel.dart';
import 'console_panel.dart';
import 'example_programs.dart';

// used for state management
final mainScaffoldKey = GlobalKey<MainScaffoldState>();

/// Represents the basic layout of the Chatbot-Studio application.
class MainScaffold extends StatefulWidget {
  MainScaffold() : super(key: mainScaffoldKey);

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  html.File _file;

  /// Whether the current source code has been imported from
  /// a file.
  bool get isImportedFromFile => _file != null;

  /// Import the source code from a file.
  Future importFromFile() async {
    FilePickerCross file = await FilePickerCross.importFromStorage(
      type: FileTypeCross.custom,
      fileExtension: '.ccml, .txt',
    );
    String contentInBase64 = file.toBase64();
    var decoded = base64.decode(contentInBase64);
    var utf8SourceCode = utf8.decode(decoded);
    loadProgram(utf8SourceCode);
  }

  /// Exports the current source code to a file.
  Future exportToFile() async {
    if (kIsWeb) {
      // download the file to the user´s 'Downloads' folder (by default)
      final sourceCode = codePanelKey.currentState.sourceCode;
      final bytes = utf8.encode(sourceCode);
      js.context.callMethod("webSaveAs", [
        html.Blob([bytes]),
        "test.ccml"
      ]);
    }
  }

  void loadProgram(String sourceCode) {
    // stop the currently running program (if any)
    stopProgram();

    // clear the console and chat history
    consolePanelKey.currentState.clear();
    chatbotPanelKey.currentState.clear();

    // set the editor´s source code
    codePanelKey.currentState.setSourceCode(sourceCode);
  }

  /// Loads a program from the [EXAMPLE_PROGRAMS] array.
  void loadExampleProgram(int index) {
    // load the source code of the selected sample program
    var sampleProgram = EXAMPLE_PROGRAMS[index];
    loadProgram(sampleProgram['src']);
  }

  void enableLogs(bool enable) {
    setState(() {
      _enabledLogs = enable;
    });
  }

  /// Runs the current program.
  ///
  /// Outputs all status or error messages on the console.
  void runProgram() async {
    if (_isRunningProgram) return;

    // clear the console
    consolePanelKey.currentState.clear();

    var programCode = codePanelKey.currentState.sourceCode;

    // print an error on the console if the program code is empty
    if (programCode.trim().isEmpty) {
      consolePanelKey.currentState
          .print('ERROR: Program is empty!', LogLevel.error);
      return;
    }

    setState(() {
      _isRunningProgram = true;
    });

    var chatbot = chatbotPanelKey.currentState;
    var lexer = Lexer(programCode);
    var parser = Parser(lexer);
    var interpreter = Interpreter(parser, chatbot);

    // print Interpreter log messages to the console panel
    // this also includes log messages from the Lexer and Parser
    var printToConsole = (msg) {
      if (!_enabledLogs) return;
      consolePanelKey.currentState.print(msg);
    };
    lexer.logPrinter = printToConsole;
    parser.logPrinter = printToConsole;
    interpreter.logPrinter = printToConsole;

    // highlight the code lines that are currently executed by the interpreter
    NodeVisitedCallback highlightCodeVisitor = (node) {
      if (node.lineStart == null || node.lineEnd == null) return;
      codePanelKey.currentState.highlightLines(
        from: node.lineStart,
        to: node.lineEnd,
      );
    };
    interpreter.onNodeVisited = highlightCodeVisitor;

    // now actually interpret the program
    setState(() {
      _runningInterpretation = interpreter.interpret();
    });
    await _runningInterpretation.future.then((_) {
      consolePanelKey.currentState
          .print('Interpretation completed successfully');
    }).catchError((error) {
      // highlight the line that caused the error in the program
      int programLineThatCausedError;
      if (error is LexerError) {
        programLineThatCausedError = error.line;
      } else if (error is ParserError) {
        programLineThatCausedError = error.token.line;
      } else if (error is RuntimeError) {
        programLineThatCausedError = error.node.lineStart;
      }
      if (programLineThatCausedError != null) {
        codePanelKey.currentState.highlightError(programLineThatCausedError);
      }

      // additionally print the error message on the console
      consolePanelKey.currentState.print(error.toString(), LogLevel.error);
    }).whenComplete(() {
      setState(() {
        _isRunningProgram = false;
        _runningInterpretation = null;
      });
    });
  }

  /// Stops the running program (=cancels interpreter).
  void stopProgram() {
    if (!_isRunningProgram) return;

    setState(() {
      _runningInterpretation?.cancel();
      _isRunningProgram = false;
    });
  }

  // Whether the program is currently running.
  bool _isRunningProgram = false;

  // Whether the interpreter should print log messages to the console.
  bool _enabledLogs = true;

  // Used to cancel the running interpreter.
  Interpretation _runningInterpretation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                ToolBar(
                  isRunningProgram: _isRunningProgram,
                  enableLogs: _enabledLogs,
                ),
                Expanded(
                  child: CodePanel(
                    isRunningProgram: _isRunningProgram,
                  ),
                ),
                ConsolePanel(
                  isRunningProgram: _isRunningProgram,
                ),
              ],
            ),
          ),
          ChatbotPanel(
            isRunningProgram: _isRunningProgram,
          ),
        ],
      ),
    );
  }
}

class ToolBar extends StatelessWidget {
  ToolBar({
    @required this.isRunningProgram,
    @required this.enableLogs,
  });

  final bool isRunningProgram;
  final bool enableLogs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.0,
      color: Colors.grey[100],
      child: Row(
        children: [
          IconButton(
            tooltip: 'Import',
            icon: Icon(Icons.file_upload),
            onPressed: () {
              mainScaffoldKey.currentState.importFromFile();
            },
          ),
          IconButton(
            tooltip: 'Export',
            icon: Icon(Icons.file_download),
            onPressed: () {
              mainScaffoldKey.currentState.exportToFile();
            },
          ),
          PopupMenuButton(
            tooltip: 'Example Programs',
            onSelected: (int index) {
              mainScaffoldKey.currentState.loadExampleProgram(index);
            },
            itemBuilder: (index) => List.generate(
              EXAMPLE_PROGRAMS.length,
              (index) => PopupMenuItem(
                value: index,
                child: Text(EXAMPLE_PROGRAMS[index]['name']),
              ),
            ),
          ),
          Expanded(child: Container()),
          Text('Enable Logs'),
          Switch(
            value: enableLogs,
            onChanged: (value) {
              mainScaffoldKey.currentState.enableLogs(value);
            },
          ),
          isRunningProgram
              ? IconButton(
                  tooltip: 'Stop chatbot',
                  icon: Icon(Icons.pause),
                  onPressed: () {
                    mainScaffoldKey.currentState.stopProgram();
                  },
                )
              : IconButton(
                  tooltip: 'Run chatbot',
                  icon: Icon(Icons.play_arrow),
                  onPressed: () {
                    mainScaffoldKey.currentState.runProgram();
                  },
                ),
          SizedBox(width: 24.0),
        ],
      ),
    );
  }
}
