import 'package:meta/meta.dart';

abstract class Chatbot {
  /// Clears all messages from the chat history.
  void clear();

  /// Appends a new message to the chat.
  void sendMessage(Message message);

  /// Removes the latest appended message.
  void removeLastMessage();

  /// Prompts the user to input something and waits for a response.
  Future<UserInputResponse> waitForInput(UserInput input);

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

enum UserInputType { singleChoice }

class UserInput {
  UserInput.singleChoice({@required this.singleChoiceTitles})
      : assert(singleChoiceTitles.isNotEmpty),
        type = UserInputType.singleChoice;

  final UserInputType type;

  // for single choice
  final List<String> singleChoiceTitles;
}

class UserInputResponse {
  UserInputResponse.singleChoice({@required this.selectedChoice})
      : type = UserInputType.singleChoice;

  final UserInputType type;

  // for single choice
  final int selectedChoice;
}
