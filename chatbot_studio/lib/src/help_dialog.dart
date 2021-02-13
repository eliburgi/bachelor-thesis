import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  static void show(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.NO_HEADER,
      width: 700.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 900.0,
        ),
        child: Column(
          children: [
            Text(
              'Documentation',
              style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 24.0),
            Flexible(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thank you for trying out this tool to build a chatbot. '
                        'This documentation is here to help you out by providing a list of '
                        'all currently available statements you can use, including examples. '
                        'I appreciate all feedback!',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: 24.0),
                      StatementInfo(
                        title: 'FLOW',
                        description:
                            'The `flow` command lets you split the conversation '
                            'into smaller (reusable) parts. Every conversation '
                            'must include one \'main\' flow',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`flow` <string> <block>',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example(
                              '`flow` \'main\'\n  <block>',
                              'This is the entry point for every conversation!',
                            ),
                            Example(
                              '`flow` \'welcome\'\n  <block>',
                              'Every conversation can include multiple other flows.',
                            ),
                            Example(
                              '`startFlow` \'welcome\'',
                              'Pauses the current flow, jumps to the given flow, executes it, and then resumes the current flow.',
                            ),
                            Example(
                              '`endFlow`',
                              'Forcefully exits the current flow.',
                            ),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'CREATE',
                        description:
                            'The `create` command lets the chatbot create '
                            'entities that it can use throughout the conversation.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`create` <entity> [<params>]',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example(
                              '`create` counter \'my-counter\'\n',
                              'A counter is a number that can be set, incremented, decremented.\nInitially 0.',
                            ),
                            Example(
                              '`create` sender \'John Doe\'\n'
                                  '  avatarUrl = \'https://url-to-img.png\'',
                              'A sender can be attached to messages being sent.',
                            ),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'SET',
                        description: 'The `set` command lets the chatbot set '
                            'global configuration properties.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`set` <config_property>',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example(
                              '`set` delay 700',
                              'All messages are now sent with a default delay of 700ms.',
                            ),
                            Example(
                              '`set` sender \'John Doe\'\n',
                              'All messages are now sent by John Doe. The sender must be CREATEed before.',
                            ),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'SEND',
                        description:
                            'The `send` command tells the chatbot to send '
                            'a message into the chat.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`send` <message> [<params>]',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example('`send` text \'Hello World\''),
                            Example(
                                '`send` image \'https://picsum.photos/200/300\''),
                            Example('`send` audio \'https://abc.myaudio.mp3\''),
                            Example('`send` event \'my-event\''),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'WAIT',
                        description:
                            'The `wait` command tells the chatbot to wait '
                            'until a specific trigger is raised.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`wait` <trigger>',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example('`wait` delay 1000', 'Waits for 1000ms.'),
                            Example('`wait` click 3',
                                'Waits until chatbot is clicked 3 times.'),
                            Example('`wait` event \'my-event\'',
                                'Waits until event \'my-event\' is sent.'),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'ACTION',
                        description:
                            'The `action` command tells the chatbot to perform '
                            'some operation, such as incrementing a counter.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`action` <action_type>',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example('`action` increment \'my-counter\' by 7'),
                            Example('`action` decrement \'my-counter\' by 3'),
                            Example(
                              '`action` set \'my-counter\' to 5',
                              'For creating counters see CREATE command further above.',
                            ),
                            Example('`action` addTag \'my-new-tag\''),
                            Example('`action` removeTag \'my-new-tag\''),
                            Example(
                              '`action` clearTags',
                              'With tags the chatbot can remember things.',
                            ),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'IF',
                        description:
                            'The `if` command lets the chatbot decide what '
                            'to do next based on some condition.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`if` <cond> <block> [else <block>]',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example(
                              '`if` counter \'my-counter\' == 7\n  `send` text \'It´s a prime number!\'\n  ...',
                              'Operators: ==, <, <=, >, >=',
                            ),
                            Example(
                                '`if` hasTag \'student\'\n  `send` text \'I grade you an A.\'\n  ...'),
                            Example(
                                '`if` hasTag \'my-new-tag\'\n  <block>\n`else`\n  <block>'),
                          ],
                        ),
                      ),
                      StatementInfo(
                        title: 'INPUT',
                        description:
                            'The `input` command lets the chatbot show different '
                            'input forms to the user and wait for the user to '
                            'submit something.',
                        grammarRules: StatementGrammarRules(
                          rules: [
                            '`input` <input_type>',
                          ],
                        ),
                        examples: StatementExamples(
                          examples: [
                            Example(
                              '`send` text \'What is your favorite color?\'\n'
                                  '`input` singleChoice\n'
                                  '  `choice` \'Green\'\n'
                                  '    <block>\n'
                                  '  `choice` \'Yellow\'\n'
                                  '    <block>\n',
                              'Lets the user select from a list of choices.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )..show();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class StatementInfo extends StatelessWidget {
  StatementInfo({
    @required this.title,
    @required this.description,
    @required this.grammarRules,
    @required this.examples,
  });

  final String title;
  final String description;
  final StatementGrammarRules grammarRules;
  final StatementExamples examples;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 12.0),
          Markup(markup: description),
          SizedBox(height: 12.0),
          grammarRules,
          SizedBox(height: 12.0),
          examples,
        ],
      ),
    );
  }
}

class StatementGrammarRules extends StatelessWidget {
  StatementGrammarRules({
    @required this.rules,
  });

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grammar Rules',
          style: const TextStyle(
            fontSize: 18.0,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.0),
        ...rules.map((rule) {
          return Container(
            padding: const EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Markup(markup: rule),
          );
        }).toList(),
      ],
    );
  }
}

@immutable
class Example {
  Example(this.code, [this.comment]);

  final String code;
  final String comment;
}

class StatementExamples extends StatelessWidget {
  StatementExamples({
    @required this.examples,
  });

  final List<Example> examples;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples',
          style: const TextStyle(
            fontSize: 18.0,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.0),
        ...examples.map((example) {
          Widget child = Container(
            padding: const EdgeInsets.all(7.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(7.0),
            ),
            child: Markup(markup: example.code),
          );
          if (example.comment != null) {
            child = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                Padding(
                  padding: const EdgeInsets.only(left: 7.0),
                  child: Text(
                    example.comment,
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
              ],
            );
          }
          return child;
        }).toList(),
      ],
    );
  }
}

class Markup extends StatefulWidget {
  Markup({
    @required this.markup,
    this.style = const TextStyle(
      color: Colors.black,
      fontFamily: 'monospace',
      fontSize: 16.0,
    ),
    this.keywordStyle = const TextStyle(
      color: Colors.blue,
      fontFamily: 'monospace',
      fontSize: 16.0,
    ),
    this.stringStyle = const TextStyle(
      color: Colors.lightGreen,
      fontFamily: 'monospace',
      fontSize: 16.0,
    ),
  });

  final String markup;
  final TextStyle style;
  final TextStyle keywordStyle;
  final TextStyle stringStyle;

  @override
  _MarkupState createState() => _MarkupState();
}

class _MarkupState extends State<Markup> {
  List<TextSpan> _spans = [];

  @override
  void initState() {
    super.initState();

    final sb = StringBuffer();
    bool parsingKeyword = false;
    bool parsingString = false;
    for (int i = 0; i < widget.markup.length; i++) {
      var c = widget.markup[i];
      if (c == '`') {
        if (parsingKeyword) {
          parsingKeyword = false;
          _spans.add(TextSpan(
            text: sb.toString(),
            style: widget.keywordStyle,
          ));
          sb.clear();
        } else {
          parsingKeyword = true;
          if (sb.isNotEmpty) {
            _spans.add(TextSpan(text: sb.toString()));
            sb.clear();
          }
        }
      } else if (c == '\'') {
        if (parsingString) {
          parsingString = false;
          sb.write(c);
          _spans.add(TextSpan(
            text: sb.toString(),
            style: widget.stringStyle,
          ));
          sb.clear();
        } else {
          parsingString = true;
          if (sb.isNotEmpty) {
            _spans.add(TextSpan(text: sb.toString()));
            sb.clear();
          }
          sb.write(c);
        }
      } else {
        sb.write(c);
      }
    }

    if (sb.isNotEmpty) {
      _spans.add(TextSpan(text: sb.toString()));
      sb.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: widget.style,
        children: _spans,
      ),
    );
  }
}
