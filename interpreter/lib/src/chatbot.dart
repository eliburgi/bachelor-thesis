import 'package:meta/meta.dart';

abstract class Chatbot {
  /// Clears all messages from the chat history.
  void clear();

  /// Appends a new message to the chat.
  void sendMessage(Message message);

  /// Removes the latest appended message.
  void removeLastMessage();

  /// Prompts the user to input something and waits for a response.
  Future<UserInputResponse> waitForInput(UserInputRequest input);

  /// Waits for the user to click on the chatbot.
  Future<void> waitForClick();

  /// Waits for the user to trigger this event.
  Future<void> waitForEvent(String eventName);
}

enum TriggerType { delay, click, event }

class Trigger {
  Trigger.delay(this.delayInMilliseconds)
      : type = TriggerType.delay,
        clickCount = 0,
        eventName = '';

  Trigger.click(this.clickCount)
      : type = TriggerType.click,
        delayInMilliseconds = 0,
        eventName = '';

  Trigger.event(this.eventName)
      : type = TriggerType.event,
        delayInMilliseconds = 0,
        clickCount = 0;

  final TriggerType type;

  final int delayInMilliseconds;
  final int clickCount;
  final String eventName;
}

class Sender {
  Sender({
    @required this.name,
    this.params = const {},
  });

  final String name;
  final Map<String, dynamic> params;
}

class Counter {
  Counter({
    @required this.name,
  });

  /// Unique identifier.
  final String name;

  /// The current value of the counter. By default `0`.
  int value = 0;
}

enum MessageType { text, image, audio, event, waitingForTrigger, typing }

class Message {
  Message({
    @required this.type,
    @required this.body,
    this.params = const {},
    this.sender,
  }) : trigger = null;

  const Message.typing()
      : type = MessageType.typing,
        body = '',
        params = const {},
        sender = null,
        trigger = null;

  const Message.waitingForTrigger(this.trigger)
      : type = MessageType.waitingForTrigger,
        body = '',
        params = const {},
        sender = null;

  final MessageType type;
  final String body;
  final Map<String, dynamic> params;
  final Sender sender;
  final Trigger trigger;
}

/// All possible types of user input.
enum UserInputType {
  singleChoice,
  freeText,
}

/// Requests the chatbot to show some type of input to the user.
class UserInputRequest {
  UserInputRequest.singleChoice({@required this.singleChoiceTitles})
      : assert(singleChoiceTitles.isNotEmpty),
        type = UserInputType.singleChoice;

  UserInputRequest.freeText()
      : type = UserInputType.freeText,
        singleChoiceTitles = null;

  /// What type of input is requested.
  final UserInputType type;

  /// Only for [UserInputType.singleChoice].
  final List<String> singleChoiceTitles;
}

/// The user has responded to the requested input.
///
/// Contains the results of the response.
class UserInputResponse {
  UserInputResponse.singleChoice(this.selectedChoiceIndex)
      : type = UserInputType.singleChoice,
        userInputText = null;

  UserInputResponse.freeText(this.userInputText)
      : type = UserInputType.freeText,
        selectedChoiceIndex = null;

  /// What type of input was requested.
  final UserInputType type;

  /// Only for [UserInputType.singleChoice].
  final int selectedChoiceIndex;

  /// Only for [UserInputType.freeText].
  final String userInputText;
}
