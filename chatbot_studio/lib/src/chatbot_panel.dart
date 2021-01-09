import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:bubble/bubble.dart';

import 'package:interpreter/interpreter.dart';

// used for state management
final chatbotPanelKey = GlobalKey<ChatbotPanelState>();

/// Visualizes a conversation with a chatbot. It does so similar to
/// messaging apps like WhatsApp.
class ChatbotPanel extends StatefulWidget {
  ChatbotPanel({
    @required this.isRunningProgram,
    this.scrollAutomatically = true,
  }) : super(key: chatbotPanelKey);

  final bool isRunningProgram;

  /// Whether the chat list should scroll automatically to the bottom
  /// whenever new messages are appened.
  final bool scrollAutomatically;

  @override
  ChatbotPanelState createState() => ChatbotPanelState();
}

class ChatbotPanelState extends State<ChatbotPanel> implements Chatbot {
  // Contains the list of all appended chat messages.
  List<Message> _messages = [];
  var _scrollController = ScrollController();

  // These completers are used for the `wait` statement.
  // For example, one completer waits until the user has clicked the
  // screen x-many times (i.e. `wait click x` statement).
  Completer<bool> _waitForClickCompleter;
  Completer<String> _waitForEventCompleter;
  String _waitForEventName;

  /// Clears all appended chat messages.
  @override
  void clear() {
    if (_messages.isEmpty) return;
    setState(() => _messages.clear());
    _scrollController.jumpTo(0.0);
  }

  /// Appends the new [message] at the end of the chatbot´s chat.
  @override
  void sendMessage(Message message) {
    // append the message to the chat
    setState(() => _messages.add(message));

    // scroll to the bottom message if automatic scrolling is enabled
    if (widget.scrollAutomatically) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        var offset = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
      });
    }
  }

  /// Removes the last message from the chatbot´s chat.
  @override
  void removeLastMessage() {
    if (_messages.isEmpty) return;
    setState(() => _messages.removeLast());
  }

  /// Prompts the user to interact with the chatbot which then responds
  /// with an appropriate response to the requested [input].
  ///
  /// For example, the chatbot may wait until the user has selected an
  /// item from a list of single-choice options.
  @override
  Future<UserInputResponse> waitForInput(UserInput input) {
    // Used to immediately return a future as return value which, however,
    // will only be completed when we receive the appropriate response.
    var completer = Completer<UserInputResponse>();

    switch (input.type) {
      case UserInputType.singleChoice:
        // The chatbot is asked to show a list of single-choice options.
        // It should wait until the user has selected one and then respond
        // with the selected option.

        // Called when the user has selected a single-choice option.
        final handleChoiceSelected = (index) {
          // Build the response from the option the user has selected.
          final response =
              UserInputResponse.singleChoice(selectedChoice: index);

          // Update the single-choice chat message to reflect
          // the selected option.
          setState(() {
            assert(_messages.last is _UserInputMessage);
            _messages.removeLast();
            _messages.add(_UserInputMessage(input: input, response: response));
          });

          // Finally, complete the returned future with this response.
          completer.complete(response);
        };

        // Append the single-choice message to the chat to allow the
        // user to select an option.
        sendMessage(_UserInputMessage(
          input: input,
          onSingleChoiceSelected: handleChoiceSelected,
        ));
        break;
    }

    // As stated further above, this future will complete when the chatbot
    // has received an appropriate response from the user.
    return completer.future;
  }

  /// Waits until the chatbot has clicked once by the user.
  @override
  Future<void> waitForClick() {
    setState(() {
      _waitForClickCompleter = Completer();
    });
    return _waitForClickCompleter.future;
  }

  /// Waits until the chatbot receives an event with the given [eventName].
  @override
  Future<void> waitForEvent(String eventName) {
    setState(() {
      _waitForEventCompleter = Completer();
      _waitForEventName = eventName;
    });
    return _waitForEventCompleter.future;
  }

  // Called internally be the chatbot whenever it receives a touch
  // input from the user.
  void handleClick() {
    setState(() {
      _waitForClickCompleter?.complete(true);
      _waitForClickCompleter = null;
    });
  }

  // Called internally by the chatbot whenever a `Trigger Event Button`
  // has been clicked.
  void handleTriggerEvent(String eventName) {
    if (eventName == _waitForEventName) {
      // chatbot is currently waiting for this event to happen
      setState(() {
        _waitForEventCompleter?.complete(eventName);
        _waitForEventCompleter = null;
        _waitForEventName = null;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget chat;
    if (_messages.isNotEmpty) {
      chat = Scrollbar(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            var message = _messages[index];

            // special case: input message
            if (message is _UserInputMessage) {
              return _UserInputItem(message);
            }

            // its a normal chat message
            if (message is Message) {
              var item = _MessageItem(
                message: message,
                prevMessage: index > 0
                    ? ((_messages[index - 1] is Message)
                        ? _messages[index - 1]
                        : null)
                    : null,
              );
              if (index == _messages.length - 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: item,
                );
              }
              return item;
            }

            throw StateError('Unknown chat message!');
          },
        ),
      );
    } else {
      chat = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 48.0),
          Text(
            'Hello, I am BeepBot 👋',
            style: TextStyle(fontSize: 18.0),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0),
          Text(
            'If you want to see me in action start writing your first '
            'script and press play :)',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Wrap the chat with a gesture detector if the chatbot is waiting for
    // the user to click x times on the chat (to trigger the conversation).
    bool isWaitingForUserClick =
        _waitForClickCompleter != null && !_waitForClickCompleter.isCompleted;
    if (isWaitingForUserClick) {
      chat = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleClick,
        child: chat,
      );
    }

    Widget chatbotAppBar = Container(
      height: 56.0,
      color: Colors.grey[100],
      child: Row(
        children: [
          SizedBox(width: 12.0),
          Image.asset(
            'assets/chatbot.png',
            height: 42.0,
          ),
          SizedBox(width: 16.0),
          Text('Chatbot'),
          Expanded(child: Container()),
          if (_waitForEventCompleter != null &&
              !_waitForEventCompleter.isCompleted)
            IconButton(
              tooltip: 'Debug: Trigger Event ($_waitForEventName)',
              icon: Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                handleTriggerEvent(_waitForEventName);
              },
            ),
          SizedBox(width: 24.0),
        ],
      ),
    );

    return Container(
      width: 350,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          chatbotAppBar,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: chat,
            ),
          ),
        ],
      ),
    );
  }
}

// Renders a single chat message.
class _MessageItem extends StatelessWidget {
  _MessageItem({
    @required this.message,
    this.prevMessage,
  });

  final Message message;
  final Message prevMessage;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (message.type) {
      case MessageType.text:
        child = Text(message.body);
        break;
      case MessageType.image:
        child = FadeInImage.memoryNetwork(
          placeholder: kTransparentImage,
          image: message.body, // = url
        );
        break;
      case MessageType.audio:
        child = CircleAvatar(
          radius: 24.0,
          backgroundColor: Colors.grey[100],
          child: IconButton(
            tooltip: 'Play Audio',
            color: Colors.black,
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              // todo: play audio
            },
          ),
        );
        break;
      case MessageType.event:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Received event: ${message.body}',
              style: Theme.of(context).textTheme.caption,
            ),
          ),
        );
        break;
      case MessageType.waitingForTrigger:
        assert(message.trigger != null);
        String text = 'Waiting ';
        switch (message.trigger.type) {
          case TriggerType.delay:
            text += 'for ${message.trigger.delayInMilliseconds} milliseconds';
            break;
          case TriggerType.click:
            text +=
                'until you clicked the chat ${message.trigger.clickCount} times';
            break;
          case TriggerType.event:
            text += 'for event ${message.trigger.eventName}';
            break;
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(text, style: Theme.of(context).textTheme.caption),
          ),
        );
        break;
      case MessageType.typing:
        child = SizedBox(
          width: 100.0,
          child: SpinKitThreeBounce(
            size: 16.0,
            color: Colors.black,
          ),
        );
        break;
      default:
        throw StateError('Unknown message type!');
    }
    var chatBubble = Bubble(
      margin: BubbleEdges.only(top: 10),
      alignment: Alignment.topLeft,
      nip: BubbleNip.leftTop,
      color: Colors.grey[100],
      child: child,
    );

    bool previousMessageSentBySameSender = message.sender != null &&
        prevMessage != null &&
        prevMessage.sender != null &&
        message.sender.name == prevMessage.sender.name;
    if (previousMessageSentBySameSender) {
      return chatBubble;
    }

    if (message.sender != null) {
      String avatarUrl;
      if (message.sender.params.containsKey('avatarUrl')) {
        avatarUrl = message.sender.params['avatarUrl'];
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarUrl != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12.0,
                      child: ClipOval(
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: avatarUrl, // = url
                        ),
                      ),
                    ),
                    Text(
                      message.sender.name,
                      style: Theme.of(context).textTheme.caption,
                    )
                  ],
                )
              : Text(
                  message.sender.name,
                  style: Theme.of(context).textTheme.caption,
                ),
          chatBubble,
        ],
      );
    }

    return chatBubble;
  }
}

// A special type of chat message that is used by the chatbot to
// provide input controls to the user.
// For example, the chatbot may render a list of single-choice options
// as a dedicated chat message.
// For the actual graphical representation see [_UserInputItem] below.
class _UserInputMessage extends Message {
  _UserInputMessage({
    @required this.input,
    this.response,
    this.onSingleChoiceSelected,
  });

  final UserInput input;
  final UserInputResponse response;
  final Function(int) onSingleChoiceSelected;
}

class _UserInputItem extends StatelessWidget {
  _UserInputItem(this.message);

  final _UserInputMessage message;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (message.input.type) {
      case UserInputType.singleChoice:
        child = Scrollbar(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(
              message.input.singleChoiceTitles.length,
              (index) {
                var button = FlatButton(
                  color: message.response != null
                      ? (index == message.response.selectedChoice
                          ? Colors.blue
                          : Colors.blue.withOpacity(0.5))
                      : Colors.blue,
                  onPressed: message.response != null
                      ? () {}
                      : () => message.onSingleChoiceSelected(index),
                  child: Text(
                    message.input.singleChoiceTitles[index],
                    style: Theme.of(context).textTheme.button.copyWith(
                          color: Colors.white,
                        ),
                  ),
                );
                if (index < message.input.singleChoiceTitles.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: button,
                  );
                }
                return button;
              },
            ),
          ),
        );
        break;
    }
    return Container(
      width: double.infinity,
      height: 64.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: child,
    );
  }
}
