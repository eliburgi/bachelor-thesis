import 'package:flutter/material.dart';

enum LogLevel {
  info,
  error,
}

// used for state management
final consolePanelKey = GlobalKey<ConsolePanelState>();

/// Represents a console that can display messages.
class ConsolePanel extends StatefulWidget {
  ConsolePanel({
    @required this.isRunningProgram,
    this.scrollAutomatically = true,
  }) : super(key: consolePanelKey);

  final bool isRunningProgram;
  final bool scrollAutomatically;

  @override
  ConsolePanelState createState() => ConsolePanelState();
}

class ConsolePanelState extends State<ConsolePanel> {
  /// Clears the console and deletes all messages.
  void clear() {
    setState(() {
      _messages.clear();
    });
  }

  /// Prints the message on the console.
  void print(String message, [LogLevel level = LogLevel.info]) {
    var style = TextStyle();
    switch (level) {
      case LogLevel.info:
        style = style.copyWith(color: Colors.blue);
        break;
      case LogLevel.error:
        style = style.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        );
        break;
    }
    setState(() {
      _messages.add(Text(message, style: style));
    });

    // scroll to the bottom message if automatic scrolling is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController == null) return;
      var offset = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    });
  }

  /// Collapses or expands the console panel.
  ///
  /// When collapsed, only the small bar with the console actions is shown
  /// and the log messages are hidden.
  void collapse(bool value) {
    setState(() {
      _collapsed = value;
      if (_collapsed) {
        _scrollController?.dispose();
        _scrollController = null;
      } else {
        _scrollController = ScrollController();
      }
    });
  }

  // A list of all messages that are printed on the console.
  List<Text> _messages = <Text>[];
  var _scrollController = ScrollController();

  // Whether the console panel is collapsed.
  // If collapsed, it will only render the small bar with the actions and no
  // logging messages.
  bool _collapsed = false;

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _collapsed ? 32.0 : 200.0,
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            height: 32.0,
            color: Colors.grey[200],
            child: Row(
              children: [
                IconButton(
                  tooltip: _collapsed ? 'Show' : 'Hide',
                  icon: _collapsed
                      ? Icon(Icons.arrow_drop_up, size: 16.0)
                      : Icon(Icons.arrow_drop_down, size: 16.0),
                  onPressed: () {
                    collapse(!_collapsed);
                  },
                ),
                Expanded(child: Container()),
                IconButton(
                  tooltip: 'Clear logs',
                  icon: Icon(Icons.delete, size: 16.0),
                  onPressed: clear,
                ),
                SizedBox(width: 24.0),
              ],
            ),
          ),
          if (!_collapsed)
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _messages[index],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
