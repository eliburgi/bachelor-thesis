import 'package:interpreter/src/token.dart';
import 'ast.dart';
import 'lexer.dart';
import 'util.dart';

/// Parser using the recursive descent method.
class Parser {
  Parser(this.lexer, {this.logPrinter}) {
    _eat();
  }

  final Lexer lexer;

  ASTNode parse() {
    _log('STARTED');
    var programNode = _parseProgram();
    _log('FINISHED');
    return programNode;
  }

  ASTNode _parseProgram() {
    _log('_parseProgram - called');

    var node = ProgramNode();

    // a program can start with any number of declarations
    // a declaration starts either with create or set
    if (_currentToken.type == TokenType.create ||
        _currentToken.type == TokenType.set_) {
      node.lineStart = _currentToken.line;
      node.declarations = _parseDeclarations();
    }

    // every program must have a flow 'main'
    node.lineStart = node.lineStart ?? _currentToken.line;
    node.mainFlow = _parseMainFlow();

    // a program can have any number of additional flows
    if (_currentToken.type == TokenType.flow) {
      node.flows = _parseFlows();
    }

    // a program always ends with an EOF
    _checkToken(TokenType.eof);

    node.lineEnd = _prevToken.line;
    return node;
  }

  List<ASTNode> _parseDeclarations() {
    _log('_parseDeclarations - called');

    var declarations = <ASTNode>[];
    while (true) {
      if (_currentToken.type == TokenType.create) {
        var statement = _parseCreateStatement();
        declarations.add(statement);
        if (_prevToken.type != TokenType.dedent) {
          _checkToken(TokenType.newLine);
        }
        continue;
      }
      if (_currentToken.type == TokenType.set_) {
        var statement = _parseSetStatement();
        declarations.add(statement);
        if (_prevToken.type != TokenType.dedent) {
          _checkToken(TokenType.newLine);
        }
        continue;
      }
      break;
    }
    return declarations;
  }

  FlowNode _parseMainFlow() {
    _log('_parseMainFlow - called');

    var node = FlowNode();

    // a flow always starts with the flow keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.flow);

    // a flow must have a unique name (represented by a string)
    // in this case 'main'
    _checkToken(TokenType.string);
    node.name = _prevToken.value;
    if (node.name != 'main') {
      _error('First flow name is not main!');
    }

    // a flow must have a block of statements
    var statements = _parseBlock();
    node.statements = statements;

    node.lineEnd = _prevToken.line;
    return node;
  }

  List<FlowNode> _parseFlows() {
    _log('_parseFlows - called');

    var flows = <FlowNode>[];
    while (_currentToken.type == TokenType.flow) {
      var flow = _parseFlowStatement();
      flows.add(flow);
    }
    return flows;
  }

  FlowNode _parseFlowStatement() {
    _log('_parseFlowStatement - called');

    var node = FlowNode();

    // a flow always starts with the flow keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.flow);

    // a flow must have a unique name (represented by a string)
    _checkToken(TokenType.string);
    node.name = _prevToken.value;

    // a flow must have a block of statements
    var statements = _parseBlock();
    node.statements = statements;

    node.lineEnd = _prevToken.line;
    return node;
  }

  List<ASTNode> _parseBlock() {
    _log('_parseBlock - called');

    var statements = <ASTNode>[];

    // a block must start with a NEWLINE
    _checkToken(TokenType.newLine);

    // a block must be INDENTed
    _checkToken(TokenType.indent);

    // a block must at least contain one statement
    TokenType type = _currentToken.type;
    do {
      var statement;
      switch (type) {
        case TokenType.set_:
          statement = _parseSetStatement();
          break;
        case TokenType.startFlow:
          statement = _parseStartFlowStatement();
          break;
        case TokenType.endFlow:
          statement = _parseEndFlowStatement();
          break;
        case TokenType.send:
          statement = _parseSendStatement();
          break;
        case TokenType.wait:
          statement = _parseWaitStatement();
          break;
        case TokenType.input:
          statement = _parseInputStatement();
          break;
        case TokenType.if_:
          statement = _parseIfStatement();
          break;
        default:
          _error('Unknown Statement: ${_currentToken.type}');
          break;
      }

      // a statement must end with a NEWLINE
      // BUT only if the statement did not already contain a NEWLINE and DEDENT
      // such as send statement with params at the end
      if (_prevToken.type != TokenType.dedent) {
        _checkToken(TokenType.newLine);
      }

      if (statement != null) {
        statements.add(statement);
      }
      type = _currentToken.type;
    } while (type == TokenType.set_ ||
        type == TokenType.startFlow ||
        type == TokenType.endFlow ||
        type == TokenType.send ||
        type == TokenType.wait ||
        type == TokenType.input ||
        type == TokenType.if_);

    // a block must end with a DEDENT
    _checkToken(TokenType.dedent);

    return statements;
  }

  Map<String, dynamic> _parseParams() {
    _log('_parseParams - called');

    var params = <String, dynamic>{};

    // params must, like a block, start with a NEWLINE and and IDENT
    _checkToken(TokenType.newLine);
    _checkToken(TokenType.indent);

    // there must at least be one parameter
    do {
      // every parameter must have a key
      _checkToken(TokenType.name);
      String paramKey = _prevToken.value;

      // there must be a '=' between key and value
      _checkToken(TokenType.assign);

      dynamic paramValue;
      if (_currentToken.type == TokenType.integer) {
        _eat();
        paramValue = _prevToken.value;
      } else if (_currentToken.type == TokenType.string) {
        _eat();
        paramValue = _prevToken.value;
      } else {
        _error('Invalid parameter value: ${_currentToken.type}');
      }
      params.putIfAbsent(paramKey, () => paramValue);

      // every parameter must end with a NEWLINE
      _checkToken(TokenType.newLine);
    } while (_currentToken.type == TokenType.name);

    // params must, like a block, end with a DEDENT
    _checkToken(TokenType.dedent);

    return params;
  }

  ASTNode _parseCreateStatement() {
    _log('_parseCreateStatement - called');

    var node = CreateStatementNode();

    // a create statement always starts with the create keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.create);

    // a create statement must specify the type of entity to be created
    if (_currentToken.type == TokenType.sender) {
      _eat();
      node.entityType = EntityType.sender;
    } else if (_currentToken.type == TokenType.counter) {
      _eat();
      node.entityType = EntityType.counter;
    } else {
      _error(
          'Invalid entity type for create statement: ${_currentToken.type}!');
    }

    // a create statement must specify a unique name for the entity
    _checkToken(TokenType.string);
    node.entityName = _prevToken.value;

    // a create statement can have optional parameters at the end
    // to check if there are parameters we need 2 lookahead tokens
    // (because a NEWLINE could also mean the start of a new statement)
    // that is the reason why this grammar is not LL1 but LL2
    if (_currentToken.type == TokenType.newLine &&
        _nextToken.type == TokenType.indent) {
      var params = _parseParams();
      node.params = params;
    }

    node.lineEnd = _prevToken.line;
    return node;
  }

  ASTNode _parseSetStatement() {
    _log('_parseSetStatement - called');

    var node = SetStatementNode();

    // a set statement always starts with the set keyword
    _checkToken(TokenType.set_);

    // a set statement must specify the name of property to be set
    if (_currentToken.type == TokenType.delay) {
      node.lineStart = _currentToken.line;
      node.property = Property.delay;

      _eat();

      // a set delay statement must specify the delay in milliseconds
      if (_currentToken.type == TokenType.dynamic_) {
        _eat();
        node.dynamicDelay = true;
      } else if (_currentToken.type == TokenType.integer) {
        _eat();
        node.delayInMilliseconds = _prevToken.value;
      } else {
        _error('Invalid value for delay property: ${_currentToken.type}');
      }
    } else if (_currentToken.type == TokenType.sender) {
      node.lineStart = _currentToken.line;
      node.property = Property.sender;

      _eat();

      // a set sender statement must specify a sender name
      _checkToken(TokenType.string);
      node.senderName = _prevToken.value;
    } else {
      _error('Invalid property type for set statement: ${_currentToken.type}!');
    }

    node.lineEnd = _prevToken.line;
    return node;
  }

  ASTNode _parseStartFlowStatement() {
    _log('_parseStartFlowStatement - called');

    var node = StartFlowStatementNode();

    // a startFlow statement always starts with the startFlow keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.startFlow);

    // a startFlow statement must specify the name of flow to be started
    _checkToken(TokenType.string);
    node.flowName = _prevToken.value;

    node.lineEnd = _prevToken.line;
    return node;
  }

  ASTNode _parseEndFlowStatement() {
    _log('_parseEndFlowStatement - called');

    var node = EndFlowStatementNode();

    // an endFlow statement always starts with the endFlow keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.endFlow);

    node.lineEnd = _prevToken.line;
    return node;
  }

  ASTNode _parseSendStatement() {
    _log('_parseSendStatement - called');

    var node = SendStatementNode();

    // a send statement must start with the send keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.send);

    // a send statement must specify the message type
    switch (_currentToken.type) {
      case TokenType.text:
        _eat();
        node.messageType = SendMessageType.text;
        break;
      case TokenType.image:
        _eat();
        node.messageType = SendMessageType.image;
        break;
      case TokenType.audio:
        _eat();
        node.messageType = SendMessageType.audio;
        break;
      case TokenType.event:
        _eat();
        node.messageType = SendMessageType.event;
        break;
      default:
        _error('Invalid message type in send statement: ${_currentToken.type}');
        break;
    }

    // a send statement must specify the message body
    _checkToken(TokenType.string);
    node.messageBody = _prevToken.value;

    // a send statement can have optional parameters at the end
    // to check if there are parameters we need 2 lookahead tokens
    // (because a NEWLINE could also mean the start of a new statement)
    // that is the reason why this grammar is not LL1 but LL2
    if (_currentToken.type == TokenType.newLine &&
        _nextToken.type == TokenType.indent) {
      var params = _parseParams();
      node.params = params;
    }

    node.lineEnd = _prevToken.line;
    return node;
  }

  ASTNode _parseWaitStatement() {
    _log('_parseWaitStatement - called');

    var node = WaitStatementNode();

    // a wait statement must start with the wait keyword
    node.lineStart = _currentToken.line;
    _checkToken(TokenType.wait);

    // a wait statement must specify a trigger
    switch (_currentToken.type) {
      case TokenType.delay:
        _eat();
        node.triggerType = TriggerType.delay;
        _checkToken(TokenType.integer);
        node.delayInMilliseconds = _prevToken.value;
        break;
      case TokenType.click:
        _eat();
        node.triggerType = TriggerType.click;
        _checkToken(TokenType.integer);
        node.clickCount = _prevToken.value;
        break;
      case TokenType.event:
        _eat();
        node.triggerType = TriggerType.event;
        _checkToken(TokenType.string);
        node.eventName = _prevToken.value;
        break;
      default:
        _error('Invalid trigger type in wait statement: ${_currentToken.type}');
        break;
    }

    node.lineEnd = _prevToken.line;
    return node;
  }

  ASTNode _parseInputStatement() {
    _log('_parseInputStatement - called');

    var node = InputStatementNode();

    // an input statement always starts with the input keyword
    _checkToken(TokenType.input);

    if (_currentToken.type == TokenType.singleChoice) {
      node.lineStart = _currentToken.line;
      node.type = InputType.singleChoice;

      _eat();

      // choices must, like a block, start with a NEWLINE and and IDENT
      _checkToken(TokenType.newLine);
      _checkToken(TokenType.indent);

      // a single choice input must have at least one choice
      var choices = <ChoiceNode>[];
      do {
        // a choice must start with the choice keyword
        _checkToken(TokenType.choice);

        var choice = ChoiceNode();
        choice.lineStart = _prevToken.line;

        // a choice must have a title
        _checkToken(TokenType.string);
        choice.title = _prevToken.value;

        // a choice must have a block of statements
        // to check if there is a block we need 2 lookahead tokens
        // (because a NEWLINE could also mean the start of a new statement)
        // that is the reason why this grammar is not LL1 but LL2
        if (_currentToken.type == TokenType.newLine &&
            _nextToken.type == TokenType.indent) {
          var statements = _parseBlock();
          choice.statements = statements;
        } else {
          _error('Choice does not contain any statements!');
        }

        choices.add(choice);
      } while (_currentToken.type == TokenType.choice);

      // choices must end with a DEDENT
      _checkToken(TokenType.dedent);

      node.singleChoiceList = choices;
    } else {
      _error('Invalid input statement: ${_currentToken.type}');
    }

    // -1 because the last choice ends with a block and therefore
    // _prevToken.line is the position of the dedent which is one line
    // further than the input statement actually spans
    node.lineEnd = _prevToken.line - 1;
    return node;
  }

  ASTNode _parseIfStatement() {
    _log('_parseIfStatement - called');

    // todo
    throw UnimplementedError();
  }

  Token _prevToken;
  Token _currentToken;
  Token _nextToken;

  /// Checks if the current token is of the given type.
  /// If yes, it consumes the current token and assign the next token.
  /// If no, it terminates the parser with an error.
  void _checkToken(TokenType type) {
    if (_currentToken.type != type) {
      _log('_checkToken - ERROR: Expected $type but was ${_currentToken.type}');
      _error('Expected $type but was ${_currentToken.type}!');
    }
    _eat();
  }

  /// Consumes the current token and read the next token.
  void _eat() {
    _prevToken = _currentToken;
    _currentToken = _nextToken;
    _nextToken = lexer.next();

    // prevent _currentToken from being null at the very beginning
    if (_currentToken == null) {
      _eat();

      // special case when the program is empty and only contains the EOF token
      if (_nextToken.type == TokenType.eof) {
        _currentToken = _nextToken;
      }
      return;
    }
  }

  List<String> errors = [];

  void _error(String message) {
    errors.add(message);
    // terminate parsing forcefully
    throw ParserError(message, _currentToken);
  }

  LogPrinter logPrinter;

  void _log(String message) {
    if (logPrinter == null) return;
    logPrinter('Parser - $message');
  }
}

class ParserError {
  ParserError(this.message, this.token);

  final String message;
  final Token token;

  @override
  String toString() => 'Parser-Error in line ${token.line}: $message';
}
