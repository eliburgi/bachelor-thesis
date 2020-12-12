import 'dart:ui';

import 'package:interpreter/src/chatbot.dart';

import 'interpreter.dart';

//! todo: free text input node
//! todo: if node
//! todo: action node
//! todo: create counter node

abstract class ASTNode {
  /// Optional. The line in which the first token that belongs to this node
  /// is located in the program code.
  int lineStart;

  /// Optional. The line in which the last token that belongs to this node
  /// is located in the program code.
  int lineEnd;

  /// Must be called as super by all sub-classes.
  Future<void> execute(RuntimeContext context) {
    // do not execute this node if the interpretation has been canceled
    if (context.canceled) {
      error('Interpretation was canceled!');
    }

    // notify the listener (if set) that this node is now visited
    if (context.onNodeVisited != null) {
      context.onNodeVisited(this);
    }

    return Future.value();
  }

  void error(String message) {
    throw RuntimeError(message, this);
  }

  void log(RuntimeContext context, String message) {
    if (context.logPrinter == null) return;
    context.logPrinter('$runtimeType - $message - context=$context');
  }
}

class ProgramNode extends ASTNode {
  ProgramNode({
    this.declarations,
    this.mainFlow,
    this.flows,
  });

  List<ASTNode> declarations;
  FlowNode mainFlow;
  List<FlowNode> flows;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called');

    // clear any previous chatbot state when starting a new program
    context.chatbot.clear();

    // put all flows into the context´s lookup table
    // this is required especially by the startFlow statement
    context.flows.putIfAbsent(mainFlow.name, () => mainFlow);
    if (flows != null) {
      for (var flow in flows) {
        context.flows.putIfAbsent(flow.name, () => flow);
      }
    }

    // execute all declarative statments before starting the main flow
    if (declarations != null) {
      for (var statement in declarations) {
        await statement.execute(context);
      }
    }

    // the actual entry point of the conversation
    await mainFlow.execute(context);

    log(context, 'execute - finished');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return false;
    }
    return other is ProgramNode;
  }

  @override
  int get hashCode => hashList([]);
}

class FlowNode extends ASTNode {
  FlowNode({
    this.name,
    this.statements,
  });

  String name = '';
  List<ASTNode> statements = [];

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called - FLOW $name');

    // add this flow to the stack because it is now open
    context.openedFlowsStack.add(name);

    // execute all statements of this flow
    for (var statement in statements) {
      await statement.execute(context);

      // end the flow if an endFlow statement was previously executed
      if (statement is EndFlowStatementNode) {
        break;
      }
    }

    // make sure all sub-flows that this flow has opened with a startFlow
    // statement have already ended before this one
    assert(context.currentFlow == name);

    // remove this flow from the stack because it is no longer open
    context.openedFlowsStack.removeLast();

    log(context, 'execute - called - FLOW $name');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return false;
    }
    return other is FlowNode &&
        this.name == other.name &&
        this.statements == other.statements;
  }

  @override
  int get hashCode => hashList([this.name]);
}

enum EntityType { sender, counter }

class CreateStatementNode extends ASTNode {
  CreateStatementNode({
    this.entityType,
    this.entityName,
    this.params = const {},
  });

  EntityType entityType;
  String entityName = '';
  Map<String, dynamic> params;

  @override
  Future<void> execute(RuntimeContext context) {
    super.execute(context);

    log(
      context,
      'execute - CREATE ENTITY [type=$entityType, name=$entityName]',
    );

    switch (entityType) {
      case EntityType.sender:
        // create the sender and put it into the map of all created senders
        var sender = Sender(name: entityName, params: params);
        context.senders.putIfAbsent(sender.name, () => sender);
        break;
      case EntityType.counter:
        // create the counter and store it in the context
        var counter = Counter(name: entityName);
        context.counters.putIfAbsent(counter.name, () => counter);
        break;
    }

    return Future.value();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return false;
    }
    return other is CreateStatementNode &&
        this.entityType == other.entityType &&
        this.entityName == other.entityName;
  }

  @override
  int get hashCode => hashList([this.entityType, this.entityName]);
}

enum Property { delay, sender }

class SetStatementNode extends ASTNode {
  SetStatementNode({
    this.property,
    this.senderName = '',
    this.dynamicDelay = false,
    this.delayInMilliseconds = 0,
  });

  Property property;

  // for 'set sender ...' statement
  String senderName;

  // for 'set delay ...' statement
  bool dynamicDelay;
  int delayInMilliseconds;

  @override
  Future<void> execute(RuntimeContext context) {
    super.execute(context);

    log(
      context,
      'execute - SETTING PROPERTY [property=$property, sender=$senderName, '
      'dynamic=$dynamicDelay, millis=$delayInMilliseconds]',
    );

    switch (property) {
      case Property.delay:
        // set delay
        if (dynamicDelay) {
          context.dynamiciallyDelayMessages = true;
        } else {
          context.delayInMilliseconds = delayInMilliseconds;
        }
        break;
      case Property.sender:
        // set sender
        if (!context.senders.containsKey(senderName)) {
          error('Cannot set sender $senderName: sender does not exist!');
        }
        context.currentSender = context.senders[senderName];
        break;
    }

    return Future.value();
  }
}

class StartFlowStatementNode extends ASTNode {
  String flowName;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - STARTING NEW FLOW $flowName');

    // lookup the flow by its name
    if (!context.flows.containsKey(flowName)) {
      error('Flow $flowName does not exist!');
    }
    var flow = context.flows[flowName];

    // start the flow
    await flow.execute(context);
  }
}

class EndFlowStatementNode extends ASTNode {
  @override
  Future<void> execute(RuntimeContext context) {
    super.execute(context);

    log(context, 'execute - FORCEFULLY ENDING CURRENT FLOW');
    // @see: FlowNode
    return Future.value();
  }
}

enum SendMessageType { text, image, audio, event }

class SendStatementNode extends ASTNode {
  SendStatementNode({
    this.messageType,
    this.messageBody,
    this.params = const {},
  });

  SendMessageType messageType;
  String messageBody;
  Map<String, dynamic> params;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called [type=$messageType, body=$messageBody]');

    // determine the delay before sending the message
    int delayInMilliseconds = 0;
    if (params.containsKey('delay') && params['delay'] is int) {
      delayInMilliseconds = params['delay'];
    } else if (context.dynamiciallyDelayMessages) {
      // compute delay for this message based on type and body
      // todo: compute based on some algorithm
      delayInMilliseconds = 300;
    } else {
      delayInMilliseconds = context.delayInMilliseconds;
    }

    if (delayInMilliseconds > 0) {
      // signal the user that the chatbot is typing a message
      context.chatbot.sendMessage(Message.typing());
      // wait for the given amount of time
      await Future.delayed(Duration(milliseconds: delayInMilliseconds));
      // remove the typing indicator
      context.chatbot.removeLastMessage();
    }

    // perform string interpolation
    var regex = RegExp(r"\$[^\s]+");
    var interpolatedBody = messageBody.replaceAllMapped(regex, (match) {
      // start at start+1 as we do not want the $ in our template
      var template = messageBody.substring(match.start + 1, match.end);
      log(context, 'TEMPLATE: $template');

      if (template == 'tags') {
        return context.tags.toString();
      }
      if (context.counters.containsKey(template)) {
        var counterValue = context.counters[template].value;
        return counterValue.toString();
      }
      // instead of throwing an error here we simply return the template.
      return template;
    });

    // create the message to be sent
    MessageType type;
    switch (this.messageType) {
      case SendMessageType.text:
        type = MessageType.text;
        break;
      case SendMessageType.image:
        type = MessageType.image;
        break;
      case SendMessageType.audio:
        type = MessageType.audio;
        break;
      case SendMessageType.event:
        type = MessageType.event;
        break;
    }
    Message message = Message(
      type: type,
      body: interpolatedBody,
      params: params,
      sender: context.currentSender, // may be null
    );

    // append the new message to the chat
    context.chatbot.sendMessage(message);

    log(context, 'execute - finished [type=$messageType, body=$messageBody]');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return false;
    }
    return other is SendStatementNode &&
        this.messageType == other.messageType &&
        this.messageBody == other.messageBody;
  }

  @override
  int get hashCode => hashList([this.messageType, this.messageBody]);
}

enum TriggerType { delay, click, event }

class WaitStatementNode extends ASTNode {
  TriggerType triggerType;
  int delayInMilliseconds = 0;
  int clickCount = 0;
  String eventName = '';

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called - WAITING [trigger=$triggerType]');

    // notify the user that the chatbot is waiting for a trigger
    Trigger trigger;
    switch (triggerType) {
      case TriggerType.delay:
        trigger = Trigger.delay(delayInMilliseconds);
        break;
      case TriggerType.click:
        trigger = Trigger.click(clickCount);
        break;
      case TriggerType.event:
        trigger = Trigger.event(eventName);
        break;
    }
    context.chatbot.sendMessage(Message.waitingForTrigger(trigger));

    // wait for the trigger to happen
    switch (triggerType) {
      case TriggerType.delay:
        // simply wait for the given amount of time
        await Future.delayed(Duration(milliseconds: delayInMilliseconds));
        break;
      case TriggerType.click:
        // wait until the user has clicked the chatbot the given amount of times
        for (var i = 0; i < clickCount; i++) {
          await context.chatbot.waitForClick();
        }
        break;
      case TriggerType.event:
        // wait until the chatbot client triggers the event
        await context.chatbot.waitForEvent(eventName);
        break;
    }

    log(context, 'execute - finished');
  }
}

enum ActionType {
  increment, // increment a counter by some value
  decrement, // decrement a counter by some value
  set_, // set a counter to some value
  addTag, // adds a new tag name
  removeTag, // removes a tag name
  clearTags, // clears all tag names
}

class ActionStatementNode extends ASTNode {
  /// Which type of action should be performed.
  ActionType actionType;

  /// The name of a counter or tag (depending on `actionType`).
  /// Will be `null` for [ActionType.clearTags].
  String name;

  /// The value for incrementing/decrementing/setting a counter.
  /// Otherwise `null`.
  int value;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called - ACTION [type=$actionType]');

    // perform the actual action
    switch (actionType) {
      case ActionType.increment:
        var counter = context.counters[name];
        if (counter == null) {
          error('Counter $name does not exist!');
        }
        counter.value += value;
        break;
      case ActionType.decrement:
        var counter = context.counters[name];
        if (counter == null) {
          error('Counter $name does not exist!');
        }
        counter.value -= value;
        break;
      case ActionType.set_:
        var counter = context.counters[name];
        if (counter == null) {
          error('Counter $name does not exist!');
        }
        counter.value = value;
        break;
      case ActionType.addTag:
        context.tags.add(name);
        break;
      case ActionType.removeTag:
        context.tags.remove(name);
        break;
      case ActionType.clearTags:
        context.tags.clear();
        break;
    }
  }
}

enum InputType { singleChoice }

class InputStatementNode extends ASTNode {
  InputType type;

  // for single choice
  List<ChoiceNode> singleChoiceList;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    switch (type) {
      case InputType.singleChoice:
        var input = UserInput.singleChoice(
          singleChoiceTitles: singleChoiceList
              .map((choice) => choice.title)
              .toList(growable: false),
        );

        // wait for the user to select a single choice
        log(context, 'execute - WAITING FOR INPUT $type');
        var response = await context.chatbot.waitForInput(input);

        // user has selected a choice
        assert(response.type == UserInputType.singleChoice);
        log(context, 'execute - USER DID INPUT $response');
        var selectedChoice = singleChoiceList[response.selectedChoice];

        // execute the selected choice statements
        await selectedChoice.execute(context);
        break;
    }
  }
}

class ChoiceNode extends ASTNode {
  String title;
  List<ASTNode> statements = [];

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called');

    for (var statement in statements) {
      await statement.execute(context);
    }

    log(context, 'execute - finished');
  }
}

enum ConditionType { counter, hasTag }

enum ConditionOp { lt, lte, gt, gte, eq }

class ConditionNode extends ASTNode {
  ConditionType type;

  List<ASTNode> thenStatements;
  List<ASTNode> elseStatements; // optional

  String name; // of counter or tag
  ConditionOp op; // for comparing a counter
  int value; // the value that a counter is compared against

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    bool isTrue = false;
    switch (type) {
      case ConditionType.counter:
        assert(name != null);
        assert(op != null);
        assert(value != null);

        var counter = context.counters[name];
        if (counter == null) {
          error('ConditionNode: Cannot find counter $name');
        }
        switch (op) {
          case ConditionOp.lt:
            isTrue = counter.value < value;
            break;
          case ConditionOp.lte:
            isTrue = counter.value <= value;
            break;
          case ConditionOp.gt:
            isTrue = counter.value > value;
            break;
          case ConditionOp.gte:
            isTrue = counter.value >= value;
            break;
          case ConditionOp.eq:
            isTrue = counter.value == value;
            break;
        }
        break;
      case ConditionType.hasTag:
        assert(name != null);
        isTrue = context.tags.contains(name);
        break;
    }

    if (isTrue) {
      log(context, 'executing `then` path');
      for (var statement in thenStatements) {
        await statement.execute(context);
      }
    } else if (elseStatements != null) {
      log(context, 'executing `else` path');
      for (var statement in elseStatements) {
        await statement.execute(context);
      }
    } else {
      log(context, 'no `else` path provided');
    }
  }
}
