import 'package:interpreter/src/ast.dart';
import 'package:interpreter/src/util.dart';
import 'package:meta/meta.dart';

import 'chatbot.dart';
import 'parser.dart';

class Interpreter {
  Interpreter(
    this.parser,
    this.chatbotDelegate, {
    this.logPrinter,
    this.onNodeVisited,
  });

  final Parser parser;
  final Chatbot chatbotDelegate;

  NodeVisitedCallback onNodeVisited;

  Interpretation interpret() {
    _log('STARTED');

    // The runtime context is passed to the AST nodes and contains important
    // state about the current interpretation.
    var context = RuntimeContext(
      chatbot: chatbotDelegate,
      logPrinter: logPrinter,
      onNodeVisited: onNodeVisited,
    );

    var run = () async {
      // Parsing the program yields the AST tree for this program.
      var tree = parser.parse();
      return await tree.execute(context).then((_) => _log('FINISHED'));
    };
    return Interpretation(run(), context);
  }

  LogPrinter logPrinter;

  void _log(String message) {
    if (logPrinter == null) return;
    logPrinter('Interpreter - $message');
  }
}

typedef NodeVisitedCallback = Function(ASTNode);

/// Represents an ongoing interpretation process.
class Interpretation {
  Interpretation(this.future, this.context);

  /// The future which completes when the interpretation is completed.
  ///
  /// May throw an error if there happens to be a runtime exception
  /// during the interpretation of the AST.
  final Future future;

  final RuntimeContext context;

  /// Cancels the ongoing interpretation.
  void cancel() {
    // By setting context.canceled to true we tell the AST nodes to
    // not execute any more code but instead throw an exception that stops
    // the ongoing execution of the AST tree.
    context.canceled = true;
  }
}

/// Used to pass important information about the interpretation around in
/// the AST.
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
  ///
  /// If `true` an error will be thrown if trying to run an AST node.
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

  /// Contains all counters created via a 'create counter ...' statement.
  ///
  /// The name of the counter is used as a key.
  Map<String, Counter> counters = {};

  /// Contains all active tags that have been added via 'action addTag ...'
  /// statement.
  Set<String> tags = {};

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

class RuntimeError {
  RuntimeError(this.message, this.node);

  final String message;

  /// The node that caused the error.
  final ASTNode node;

  @override
  String toString() => 'Runtime-Error in line ${node.lineStart}: $message';
}
