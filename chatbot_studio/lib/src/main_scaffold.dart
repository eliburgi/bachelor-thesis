import 'package:async/async.dart';
import 'package:chatbot_studio/src/console_panel.dart';
import 'package:flutter/material.dart';
import 'package:interpreter/interpreter.dart';

import 'chatbot_panel.dart';
import 'code_panel.dart';

const List<Map<String, dynamic>> EXAMPLE_PROGRAMS = [
  {
    'name': 'Hello World',
    'src': '''
set delay 700
flow 'main'
  send text 'Hello World'
''',
  },
  {
    'name': 'Hello Image',
    'src': '''
set delay 700
flow 'main'
  send text 'This is my new favorite image'
  send text 'I hope you like it'
  send image 'https://picsum.photos/200'
''',
  },
  {
    'name': 'Hello Audio',
    'src': '''
set delay 700
flow 'main'
  send text 'This is my new song'
  send text 'I hope you like it'
  send audio 'TODO: Paste URL'
''',
  },
  {
    'name': 'Hello Event',
    'src': '''
set delay 700
flow 'main'
  send text 'This is my new song'
  send text 'Here is the new task you have to solve'
  send event 'task'
  send text 'Now, complete your task!'
  wait event 'task'
  send text 'Great, you have completed the task!'
''',
  },
  {
    'name': 'Wait for Triggers',
    'src': '''
set delay 700
flow 'main'
  send text 'Hello. I will introduce you into Triggers.'
  send text 'The wait delay ... statement waits for the given amount of milliseconds.'
  wait delay 1000
  send text 'One second later ...'
  send text 'The wait click ... statement waits for you to click the screen the given amount of times.'
  wait click 3
  send text 'You´ve clicked the screen 3 times. Congrats ;P'
''',
  },
  {
    'name': 'Infinite Loop',
    'src': '''
set delay 700
flow 'main'
  send text 'I'
  send text 'am'
  send text 'an'
  send text 'infinite loop'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Infinite Loop with Image',
    'src': '''
set delay 700
flow 'main'
  send text 'I'
  send text 'am'
  send image 'https://picsum.photos/200'
  send text 'infinite loop'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Infinite Loop with Sender',
    'src': '''
create sender 'Laura B.'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
set sender 'Laura B.'
set delay 700

flow 'main'
  send text 'I'
  send text 'am'
  send text 'infinite loop'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Single Choice Input',
    'src': '''
create sender 'Laura B.'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
set sender 'Laura B.'
set delay 700

flow 'main'
  send text 'Hello'
  send text 'What is your favorite color?'
  input singleChoice
    choice 'green'
      send text 'Sounds like you are a nature person 🌳'
    choice 'orange'
      send text 'You like pumpkins 🎃'
    choice 'yellow'
      send text 'You are so bright :)'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
];

// used for state management
final mainScaffoldKey = GlobalKey<MainScaffoldState>();

/// Represents the basic layout of the Chatbot-Studio application.
class MainScaffold extends StatefulWidget {
  MainScaffold() : super(key: mainScaffoldKey);

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  /// Opens a file and loads its content as program.
  void openFile() {}

  /// Saves the current program as a file.
  void saveFile() {}

  void loadExampleProgram(int index) {
    // stop the currently running program (if any)
    stopProgram();

    var program = EXAMPLE_PROGRAMS[index];
    consolePanelKey.currentState.clear();
    chatbotPanelKey.currentState.clear();
    codePanelKey.currentState.setProgramCode(program['src']);
  }

  void enableLogs(bool enable) {
    setState(() {
      _enabledLogs = enable;
    });
  }

  /// Runs the current program.
  ///
  /// Outputs all status or error messages on the console.
  void runProgram() {
    if (_isRunningProgram) return;

    // clear the console
    consolePanelKey.currentState.clear();

    // print an error on the console if the program code is empty
    if (codePanelKey.currentState.programCode.trim().isEmpty) {
      consolePanelKey.currentState
          .print('ERROR: Program is empty!', LogLevel.error);
      return;
    }

    setState(() {
      _isRunningProgram = true;
    });

    var chatbot = chatbotPanelKey.currentState;
    _interpreter = Interpreter(chatbot);

    // print Interpreter log messages to the console panel
    // this also includes log messages from the Lexer and Parser
    var printToConsole = (msg) {
      if (!_enabledLogs) return;
      consolePanelKey.currentState.print(msg);
    };
    _interpreter.logPrinter = printToConsole;

    // highlight the code lines that are currently executed by the interpreter
    NodeVisitedCallback highlightCodeVisitor = (node) {
      if (node.lineStart == null || node.lineEnd == null) return;
      codePanelKey.currentState.highlightLines(
        from: node.lineStart,
        to: node.lineEnd,
      );
    };
    _interpreter.onNodeVisited = highlightCodeVisitor;

    // interpret the program code
    var program = codePanelKey.currentState.programCode;
    _runningProgramOperation = CancelableOperation.fromFuture(
      _interpreter.interpret(program),
    );
    _runningProgramOperation.value.then((_) {
      // succcess
    }).catchError((error) {
      consolePanelKey.currentState.print(error, LogLevel.error);
    }).whenComplete(() {
      setState(() {
        _isRunningProgram = false;
        _runningProgramOperation = null;
      });
    });
  }

  /// Stops the running program (=cancels interpreter).
  void stopProgram() {
    if (!_isRunningProgram) return;

    setState(() {
      _interpreter.cancel();
      _runningProgramOperation?.cancel();
      _isRunningProgram = false;
    });
  }

  // Whether the program is currently running.
  bool _isRunningProgram = false;

  // Whether the interpreter should print log messages to the console.
  bool _enabledLogs = true;

  // Used to stop a running program.
  CancelableOperation _runningProgramOperation;
  Interpreter _interpreter;

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
          PopupMenuButton(
            tooltip: 'Example Programs',
            onSelected: (index) {
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
