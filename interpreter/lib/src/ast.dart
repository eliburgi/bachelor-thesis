import 'dart:ui';

import 'chatbot.dart';
import 'interpreter.dart';
import 'string_interpolation.dart';

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
    this.block,
  });

  String name = '';
  BlockNode block;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called - FLOW $name');

    // add this flow to the stack because it is now open
    context.openedFlowsStack.add(name);

    // execute the block
    try {
      await block.execute(context);
    } on EndFlowException {
      log(context, 'Flow $name executed.');
    }

    // make sure all sub-flows that this flow has opened with a startFlow
    // statement have already ended before this one
    assert(context.currentFlow == name);

    // remove this flow from the stack because it is no longer open
    context.openedFlowsStack.removeLast();

    log(context, 'execute - called - FLOW $name');
  }
}

class BlockNode extends ASTNode {
  BlockNode({this.statements});

  List<ASTNode> statements = [];

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    // execute all statements of this block
    for (var statement in statements) {
      await statement.execute(context);

      // end the flow if an endFlow statement was just executed
      if (statement is EndFlowStatementNode) {
        break;
      }
    }
  }
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

class EndFlowException implements Exception {}

class EndFlowStatementNode extends ASTNode {
  @override
  Future<void> execute(RuntimeContext context) {
    super.execute(context);

    log(context, 'execute - FORCEFULLY ENDING CURRENT FLOW');
    throw EndFlowException();
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
      //? TODO: Compute based on some algorithm.
      // Compute delay for this message based on type and body.
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

    // Create the message to be sent.
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
      body: interpolateString(context, messageBody),
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

  /// Only for [ActionType.increment], [ActionType.decrement] and .
  /// [ActionType.set_]
  String counterName;

  /// Only for [ActionType.increment], [ActionType.decrement] and .
  /// [ActionType.set_]
  ///
  /// The value for incrementing/decrementing/setting a counter.
  int counterOpValue;

  /// Only for [ActionType.addTag] and [ActionType.removeTag].
  String tagKey;

  /// Only for [ActionType.addTag].
  String tagValue;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    log(context, 'execute - called - ACTION [type=$actionType]');

    // perform the actual action
    switch (actionType) {
      case ActionType.increment:
        assert(counterName != null);
        assert(counterOpValue != null);

        var counter = context.counters[counterName];
        if (counter == null) {
          error('Counter $counterName does not exist!');
        }
        counter.value += counterOpValue;
        break;
      case ActionType.decrement:
        assert(counterName != null);
        assert(counterOpValue != null);

        var counter = context.counters[counterName];
        if (counter == null) {
          error('Counter $counterName does not exist!');
        }
        counter.value -= counterOpValue;
        break;
      case ActionType.set_:
        assert(counterName != null);
        assert(counterOpValue != null);

        var counter = context.counters[counterName];
        if (counter == null) {
          error('Counter $counterName does not exist!');
        }
        counter.value = counterOpValue;
        break;
      case ActionType.addTag:
        assert(tagKey != null);
        assert(tagValue != null);
        context.tags[tagKey] = interpolateString(context, tagValue);
        break;
      case ActionType.removeTag:
        assert(tagKey != null);
        context.tags.remove(tagKey);
        break;
      case ActionType.clearTags:
        context.tags.clear();
        break;
    }
  }
}

/// All possible types of input statements.
enum InputType {
  /// The user is presented a list of choices from which he
  /// should select exactly one.
  ///
  /// For example, the chatbot could ask the user about his favorite color.
  /// The choices then could e.g. be `blue` and `green`.
  ///
  /// The chatbot can then respond differently depending on the
  /// selected choice.
  singleChoice,

  /// The user is presented a text field and should enter some text.
  ///
  /// For example, the chatbot could ask the user what his name is.
  ///
  /// The chatbot can then respond differently depending on the
  /// text that was input.
  freeText,
}

class InputStatementNode extends ASTNode {
  /// What type of input this node represents.
  InputType type;

  /// Only for [InputType.singleChoice].
  List<ChoiceNode> choices;

  /// Only for [InputType.freeText].
  ///
  /// The text patterns the chatbot can respond to.
  /// Each pattern matches to a response contained in [responses].
  List<Pattern> patterns;

  /// Only for [InputType.freeText].
  ///
  /// The actual responses.
  List<ResponseNode> responses;

  /// Only for [InputType.freeText]. Optional.
  ///
  /// If none of the [patterns] match this fallback response (if given)
  /// will be executed by the chatbot.
  ResponseNode fallback;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);

    assert(type != null);
    switch (type) {
      // Logic for single-choice input.
      case InputType.singleChoice:
        assert(choices != null && choices.isNotEmpty);

        // Create the input request for the chatbot.
        final input = UserInputRequest.singleChoice(
          singleChoiceTitles:
              choices.map((choice) => choice.title).toList(growable: false),
        );

        // Wait for the user to select a single choice.
        log(context, 'execute - WAITING FOR INPUT $type');
        var response = await context.chatbot.waitForInput(input);
        assert(response.type == UserInputType.singleChoice);

        // User has selected a choice.
        log(context, 'execute - USER DID INPUT $response');
        var selectedChoice = choices[response.selectedChoiceIndex];

        // Now execute the selected choice.
        await selectedChoice.execute(context);
        break;
      // Logic for free-text input.
      case InputType.freeText:
        assert(patterns != null && patterns.isNotEmpty);
        assert(responses != null && responses.isNotEmpty);

        // Create the input request for the chatbot.
        final input = UserInputRequest.freeText();

        // Wait for the user to enter some text.
        log(context, 'execute - WAITING FOR INPUT $type');
        var response = await context.chatbot.waitForInput(input);
        assert(response.type == UserInputType.freeText);

        // User has entered some text.
        log(context, 'execute - USER DID INPUT $response');
        final userInputText = response.userInputText;

        // Store the entered text in the context.
        context.userInputText = userInputText;

        // Try to match the entered text to a pattern.
        Pattern matchingPattern;
        for (var pattern in patterns) {
          if (pattern.matches(userInputText)) {
            matchingPattern = pattern;
            break;
          }
        }

        // A pattern matches the given text.
        if (matchingPattern != null) {
          // Execute the matching pattern´s response.
          final responseName = matchingPattern.responseName;
          final response = responses.firstWhere(
            (response) => response.name == responseName,
            orElse: () => null,
          );
          if (response == null) {
            error('No response found with name: $responseName');
          }
          await response.execute(context);
        } else {
          // No matching pattern detected.
          // Perform fallback if given. Otherwise do nothing.
          if (fallback != null) {
            await fallback.execute(context);
          }
        }
        break;
    }
  }
}

/// Used with a [InputType.singleChoice].
///
/// Represents a single choice that can be selected by the user.
class ChoiceNode extends ASTNode {
  /// The title of this choice.
  ///
  /// This title is visible to the user in the chatbot.
  String title;

  /// The statements that are executed if this choice is selected
  /// by the user.
  BlockNode block;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);
    await block.execute(context);
  }
}

/// Used with a [InputType.freeText].
///
/// Represents a text pattern that the chatbot can respond to.
class Pattern {
  /// A non-empty list of strings that represent this pattern.
  ///
  /// These strings are typically regular expressions, but can
  /// also just be simple strings.
  List<String> strings;

  /// The unique name of the response that should be executed by
  /// the chatbot if any of the [strings] matches the user´s text input.
  String responseName;

  /// Whether this pattern matches the given [userInputText].
  ///
  /// This pattern matches a given text if any of its [strings]
  /// matches the given [userInputText].
  bool matches(String userInputText) {
    for (var string in strings) {
      var regex = RegExp(
        r'' + string + '',
        caseSensitive: false,
      );
      // if (string.startsWith('/')) {
      //   regex = RegExp(string);
      // }
      if (regex.hasMatch(userInputText)) {
        return true;
      }
    }
    return false;
  }
}

/// Used with a [InputType.freeText].
///
/// Represents a single response.
class ResponseNode extends ASTNode {
  /// The unique name of this response.
  String name;

  /// The statements that are executed if this response is determined.
  BlockNode block;

  @override
  Future<void> execute(RuntimeContext context) async {
    super.execute(context);
    await block.execute(context);
  }
}

/// All types of condition statements.
enum ConditionType {
  /// Used to compare the value of a counter against some integer value.
  ///
  /// For all comparison operations see [ConditionOp].
  counter,

  /// Used to check whether the chatbot has a certain tag stored.
  hasTag,
}

/// For counter comparisons.
enum ConditionOp { lt, lte, gt, gte, eq }

/// Represents a condition that can either be `true` or `false`.
///
/// Depending on this condition, the chatbot can perform different actions.
class ConditionNode extends ASTNode {
  /// What type of condition it is.
  ///
  /// See: [ConditionType].
  ConditionType type;

  /// Statements that are executed if this condition is `true`.
  BlockNode thenBlock;

  /// Optional. Statements that are executed if this condition is `false`.
  BlockNode elseBlock;

  /// The name of the counter or tag that is subject of this condition.
  String name; // of counter or tag

  /// Only if [type] is [ConditionType.counter].
  ///
  /// What comparison operator (<, >, ...) is used to compare
  /// the counter to an integer value.
  ConditionOp op;

  /// Only if [type] is [ConditionType.counter].
  ///
  /// The integer value that the counter is compared against.
  int value;

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
        isTrue = context.tags.containsKey(name);
        break;
    }

    if (isTrue) {
      log(context, 'executing `then` path');
      await thenBlock.execute(context);
    } else if (elseBlock != null) {
      log(context, 'executing `else` path');
      await elseBlock.execute(context);
    } else {
      log(context, 'no `else` path provided');
    }
  }
}
