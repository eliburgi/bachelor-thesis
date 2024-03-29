import 'dart:convert';
import 'dart:js' as js;
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker_cross/file_picker_cross.dart';

import 'package:interpreter/interpreter.dart';
import 'chatbot_panel.dart';
import 'code_panel.dart';
import 'console_panel.dart';
import 'help_dialog.dart';
import 'sample_programs.dart';

// used for state management
final mainScaffoldKey = GlobalKey<MainScaffoldState>();

/// Represents the basic layout of the Chatbot-Studio application.
class MainScaffold extends StatefulWidget {
  MainScaffold() : super(key: mainScaffoldKey);

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  // The file from which the current source code has originally
  // been imported (may be null).
  // When the user exports his source code, the exported file
  // will have the same name as the originally imported file.
  FilePickerCross _file;

  /// Import the source code from a file.
  Future importFromFile() async {
    _file = await FilePickerCross.importFromStorage(
      type: FileTypeCross.custom,
      fileExtension: '.ccml, .txt',
    );
    String contentInBase64 = _file.toBase64();
    var decodedSourceCode = base64.decode(contentInBase64);
    var sourceCodeStr = String.fromCharCodes(decodedSourceCode);
    loadProgram(sourceCodeStr);
  }

  /// Exports the current source code to a file.
  Future exportToFile() async {
    if (kIsWeb) {
      // download the file to the user´s 'Downloads' folder (by default)
      String filename = _file != null ? _file.fileName : 'chatbot.ccml';
      String sourceCode = codePanelKey.currentState.sourceCode;
      final bytes = utf8.encode(sourceCode);
      js.context.callMethod("webSaveAs", [
        html.Blob([bytes]),
        filename,
      ]);
    } else {
      print('Exporting to a file is not supported on this platform!');
    }
  }

  /// Loads the given [sourceCode] into the editor.
  void loadProgram(String sourceCode) {
    // stop the currently running program (if any)
    stopProgram();

    // clear the console, chatbot and code editor
    consolePanelKey.currentState.clear();
    chatbotPanelKey.currentState.clear();
    codePanelKey.currentState.clear();

    // set the editor´s source code
    codePanelKey.currentState.setSourceCode(sourceCode);
  }

  /// Loads a sample program from the [SAMPLE_PROGRAMS] array.
  void loadSampleProgram(int index) {
    // load the source code of the selected sample program
    var sampleProgram = SAMPLE_PROGRAMS[index];
    loadProgram(sampleProgram['src']);
  }

  /// Enables or disables logging. If enabled, all info and error
  /// messages from the lexer, parser or interpreter will be printed
  /// on the console panel.
  void enableLogs(bool enable) {
    setState(() {
      _enabledLogs = enable;
    });
  }

  /// Starts executing the current CCML script.
  void runProgram() async {
    if (_isRunningProgram) return;

    // Clear the console and un-focus the code editor.
    consolePanelKey.currentState.clear();
    codePanelKey.currentState.unfocus();

    // Read the CCML script from the [CodePanel].
    String script = codePanelKey.currentState.sourceCode;

    // Print an error on the console if the program code is empty.
    if (script.trim().isEmpty) {
      consolePanelKey.currentState
          .print('ERROR: Program is empty!', LogLevel.error);
      return;
    }

    // Create the interpreter.
    var chatbot = chatbotPanelKey.currentState;
    var lexer = Lexer(script);
    var parser = Parser(lexer);
    var interpreter = Interpreter(parser, chatbot);

    // Print Interpreter log messages to the console panel.
    // This also includes log messages from the Lexer and Parser.
    var printToConsole = (msg) {
      if (!_enabledLogs) return;
      consolePanelKey.currentState.print(msg);
    };
    lexer.logPrinter = printToConsole;
    parser.logPrinter = printToConsole;
    interpreter.logPrinter = printToConsole;

    // Highlight the code lines that are currently executed by
    // the interpreter.
    NodeVisitedCallback highlightCodeVisitor = (node) {
      if (node.lineStart == null || node.lineEnd == null) return;
      codePanelKey.currentState
          .highlightLines(from: node.lineStart, to: node.lineEnd);
    };
    interpreter.onNodeVisited = highlightCodeVisitor;

    // Execute the script.
    setState(() => _isRunningProgram = true);
    setState(() {
      _runningInterpretation = interpreter.interprete();
    });
    await _runningInterpretation.future.then((_) {
      consolePanelKey.currentState
          .print('Interpretation completed successfully');
      codePanelKey.currentState.highlightLines(from: null, to: null);
    }).catchError((error) {
      // Highlight the line that caused the error in the program.
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
      // Additionally print the error message on the console.
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
  void initState() {
    super.initState();
    // Instead of showing an empty editor we show a `Hello World` program
    // when the user first opens this app.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadSampleProgram(0);
    });
  }

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

/// Contains buttons and actions such as importing/exporting files,
/// selecting a sample program, starting the program, etc.
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
          SizedBox(width: 24.0),
          Text(
            'Chatbot-Creator',
            style: TextStyle(fontSize: 20.0),
          ),
          SizedBox(width: 24.0),
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
              mainScaffoldKey.currentState.loadSampleProgram(index);
            },
            itemBuilder: (index) => List.generate(
              SAMPLE_PROGRAMS.length,
              (index) => PopupMenuItem(
                value: index,
                child: Text(SAMPLE_PROGRAMS[index]['name']),
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
          IconButton(
            tooltip: 'Help',
            icon: Icon(Icons.help_outline_rounded),
            onPressed: () {
              HelpDialog.show(context);
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
