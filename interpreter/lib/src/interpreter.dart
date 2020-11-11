import 'package:interpreter/src/ast.dart';
import 'package:interpreter/src/util.dart';
import 'package:meta/meta.dart';

import 'chatbot.dart';
import 'lexer.dart';
import 'parser.dart';

class Interpreter {
  Interpreter(
    this.chatbotDelegate, {
    this.logPrinter,
    this.onNodeVisited,
  });

  final Chatbot chatbotDelegate;

  NodeVisitedCallback onNodeVisited;

  Future<void> interpret(String program) async {
    var lexer = Lexer(program, logPrinter: logPrinter);
    var parser = Parser(lexer, logPrinter: logPrinter);

    var tree = parser.parse();
    _runtimeContext = RuntimeContext(
      chatbot: chatbotDelegate,
      logPrinter: logPrinter,
      onNodeVisited: onNodeVisited,
    );
    _log('STARTED');
    await tree.execute(_runtimeContext);
    _log('FINISHED');
  }

  Future<void> interpretAST(ASTNode tree) async {
    _runtimeContext = RuntimeContext(
      chatbot: chatbotDelegate,
      logPrinter: logPrinter,
      onNodeVisited: onNodeVisited,
    );
    await tree.execute(_runtimeContext);
  }

  /// Cancels the interpreter.
  void cancel() {
    if (_runtimeContext == null) return;
    _runtimeContext.canceled = true;
    _log('cancel - CANCELED INTERPRETATION');
  }

  RuntimeContext _runtimeContext;

  LogPrinter logPrinter;

  void _log(String message) {
    if (logPrinter == null) return;
    logPrinter('Interpreter - $message');
  }
}

typedef NodeVisitedCallback = Function(ASTNode);

class RuntimeContext {
  RuntimeContext({
    @required this.chatbot,
    this.logPrinter,
    this.onNodeVisited,
  });

  /// The ASTNodes delegate the actual work of showing messages, asking user
  /// for input, etc. to the chatbot.
  final Chatbot chatbot;

  /// Optional. If set, the ASTNodes will log messages to the [logPrinter].
  final LogPrinter logPrinter;

  /// Optional. If set, the ASTNodes will notify this callback when they are
  /// visited.
  final NodeVisitedCallback onNodeVisited;

  /// Whether the interpretation has been canceled.
  bool canceled = false;

  /// A lookup table that contains references to all flows with their
  /// names as keys.
  Map<String, ASTNode> flows = {};

  /// A stack containing all currently open flows.
  List<String> openedFlowsStack = [];

  /// The most recent flow that is currently open.
  ///
  /// Represented by the top-most flow on the [openedFlowsStack].
  String get currentFlow =>
      openedFlowsStack.isNotEmpty ? openedFlowsStack.last : null;

  bool get hasCurrentFlow => currentFlow != null;

  /// Optional. The current sender that is sending messages.
  ///
  /// Every message sent via a 'send' statement has the current sender
  /// attached to it.
  Sender currentSender;

  /// Contains all senders created via a 'create sender ...' statement.
  ///
  /// The name of the sender is used as a key.
  Map<String, Sender> senders = {};

  /// Whether messages sent via 'send' statement should be delayed dynamically.
  ///
  /// Longer text messages will have a greater delay than shorter messages.
  /// If `true` this will be used and not [delayInMilliseconds].
  ///
  /// Set via 'set delay dynamic' statement.
  bool dynamiciallyDelayMessages = false;

  /// Set via 'set delay ...' statement.
  int delayInMilliseconds = 0;
}
