import 'dart:async';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:interpreter/interpreter.dart';
import 'package:transparent_image/transparent_image.dart';

// used for state management
final chatbotPanelKey = GlobalKey<ChatbotPanelState>();

class ChatbotPanel extends StatefulWidget {
  ChatbotPanel({
    @required this.isRunningProgram,
    this.scrollAutomatically = true,
  }) : super(key: chatbotPanelKey);

  final bool isRunningProgram;
  final bool scrollAutomatically;

  @override
  ChatbotPanelState createState() => ChatbotPanelState();
}

class ChatbotPanelState extends State<ChatbotPanel> implements Chatbot {
  @override
  void clear() {
    if (_messages.isEmpty) return;

    setState(() {
      _messages.clear();
    });
    _scrollController.jumpTo(0.0);
  }

  @override
  void sendMessage(Message message) {
    setState(() {
      _messages.add(message);
    });

    // scroll to the bottom message if automatic scrolling is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var offset = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    });
  }

  @override
  void removeLastMessage() {
    if (_messages.isEmpty) return;

    setState(() {
      _messages.removeLast();
    });
  }

  @override
  Future<UserInputResponse> waitForInput(UserInput input) {
    var completer = Completer<UserInputResponse>();

    var inputItem;
    switch (input.type) {
      case UserInputType.singleChoice:
        inputItem = _UserInputItem(
          input: input,
          onSingleChoiceSelected: (index) {
            var response = UserInputResponse.singleChoice(
              selectedChoice: index,
            );

            // update chat
            setState(() {
              assert(_messages.last is _UserInputItem);
              _messages.removeLast();
              _messages.add(_UserInputItem(input: input, response: response));
            });

            // notify the interpreter about the response
            completer.complete(response);
          },
        );
        break;
    }

    // add the input request to the bottom of the chat
    // e.g. for single choice this is a list of buttons
    setState(() {
      _messages.add(inputItem);
    });

    return completer.future;
  }

  @override
  Future<void> waitForClick() {
    setState(() {
      _waitForClickCompleter = Completer();
    });
    return _waitForClickCompleter.future;
  }

  @override
  Future<void> waitForEvent(String eventName) {
    setState(() {
      _waitForEventCompleter = Completer();
      _waitForEventName = eventName;
    });
    return _waitForEventCompleter.future;
  }

  void handleClick() {
    setState(() {
      _waitForClickCompleter.complete(true);
      _waitForClickCompleter = null;
    });
  }

  void handleTriggerEvent(String eventName) {
    if (eventName == _waitForEventName) {
      // chatbot is currently waiting for this event to happen
      setState(() {
        _waitForEventCompleter.complete(eventName);
        _waitForEventCompleter = null;
        _waitForEventName = null;
      });
    }
  }

  // list of chat messages
  // chat may also contain input items therefore I use dynamic type here
  // instead of Message type
  List<dynamic> _messages = [];
  var _scrollController = ScrollController();

  Completer<bool> _waitForClickCompleter;
  Completer<String> _waitForEventCompleter;
  String _waitForEventName;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget chat = Scrollbar(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          // its a normal chat message
          if (_messages[index] is Message) {
            var item = _MessageItem(
              message: _messages[index],
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

          // its a user input request
          if (_messages[index] is _UserInputItem) {
            return _messages[index];
          }

          throw StateError('Unknown chat message!');
        },
      ),
    );

    // wrap the chat with a gesture detector if the chatbot is waiting for
    // the user to click x times on the chat (to trigger the conversation)
    bool isWaitingForUserClick =
        _waitForClickCompleter != null && !_waitForClickCompleter.isCompleted;
    if (isWaitingForUserClick) {
      chat = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleClick,
        child: chat,
      );
    }

    return Container(
      width: 350,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 42.0,
            color: Colors.grey[100],
            child: (_waitForEventCompleter != null &&
                    !_waitForEventCompleter.isCompleted)
                ? Row(
                    children: [
                      SizedBox(width: 24.0),
                      IconButton(
                        tooltip: 'Debug: Trigger Event',
                        icon: Icon(Icons.edit, color: Colors.black),
                        onPressed: () {
                          handleTriggerEvent(_waitForEventName);
                        },
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
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

class _UserInputItem extends StatelessWidget {
  _UserInputItem({
    @required this.input,
    this.response,
    this.onSingleChoiceSelected,
  });

  final UserInput input;
  final UserInputResponse response;

  final Function(int) onSingleChoiceSelected;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (input.type) {
      case UserInputType.singleChoice:
        child = Scrollbar(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(
              input.singleChoiceTitles.length,
              (index) {
                var button = FlatButton(
                  color: response != null
                      ? (index == response.selectedChoice
                          ? Colors.blue
                          : Colors.blue.withOpacity(0.5))
                      : Colors.blue,
                  onPressed: response != null
                      ? () {}
                      : () => onSingleChoiceSelected(index),
                  child: Text(
                    input.singleChoiceTitles[index],
                    style: Theme.of(context).textTheme.button.copyWith(
                          color: Colors.white,
                        ),
                  ),
                );
                if (index < input.singleChoiceTitles.length - 1) {
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
