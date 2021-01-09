/// Source codes of multiple sample programs.
const List<Map<String, dynamic>> SAMPLE_PROGRAMS = [
  {
    'name': 'Hello World',
    'src': '''
set delay 700
flow 'main'
  send text 'Hello World'
''',
  },
  {
    'name': 'Hello Image',
    'src': '''
set delay 700
flow 'main'
  send text 'This is my new favorite image'
  send text 'I hope you like it'
  send image 'https://picsum.photos/200'
''',
  },
  {
    'name': 'Hello Audio',
    'src': '''
set delay 700
flow 'main'
  send text 'This is my new song'
  send text 'I hope you like it'
  send audio 'TODO: Paste URL'
''',
  },
  {
    'name': 'Hello Event',
    'src': '''
set delay 700
flow 'main'
  send text 'This is my new song'
  send text 'Here is the new task you have to solve'
  send event 'task'
  send text 'Now, complete your task!'
  wait event 'task'
  send text 'Great, you have completed the task!'
''',
  },
  {
    'name': 'Wait for Triggers',
    'src': '''
set delay 700
flow 'main'
  send text 'Hello. I will introduce you into Triggers.'
  send text 'The wait delay ... statement waits for the given amount of milliseconds.'
  wait delay 1000
  send text 'One second later ...'
  send text 'The wait click ... statement waits for you to click the screen the given amount of times.'
  wait click 3
  send text 'You´ve clicked the screen 3 times. Congrats ;P'
  send text 'Finally you can wait for events to happen'
  send event 'say-welcome'
  send text 'Now we wait until the chatbot triggers this event'
  wait event 'say-welcome'
  send text 'Great. You´ve found the triger event button ;P'
  send text 'This is the end of the wait statement demo'
  send text 'Bye bye :)'
''',
  },
  {
    'name': 'Infinite Loop',
    'src': '''
set delay 700
flow 'main'
  send text 'I'
  send text 'am'
  send text 'an'
  send text 'infinite loop'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Infinite Loop with Image',
    'src': '''
set delay 700
flow 'main'
  send text 'I'
  send text 'am'
  send image 'https://picsum.photos/200'
  send text 'infinite loop'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Infinite Loop with Sender',
    'src': '''
create sender 'Laura B.'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
set sender 'Laura B.'
set delay 700

flow 'main'
  send text 'I'
  send text 'am'
  send text 'infinite loop'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Single Choice Input',
    'src': '''
create sender 'Laura B.'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
set sender 'Laura B.'
set delay 700

flow 'main'
  send text 'Hello'
  send text 'What is your favorite color?'
  input singleChoice
    choice 'green'
      send text 'Sounds like you are a nature person 🌳'
    choice 'orange'
      send text 'You like pumpkins 🎃'
    choice 'yellow'
      send text 'You are so bright :)'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Hello Action',
    'src': '''
set delay 1000
create counter 'myCounter'

flow 'main'
  send text 'Let´s have sun fun with actions! Shall we?'
  send text '1) You can increment the value of a counter'
  action increment 'myCounter' by 50
  send text 'The new value of this counter: \$myCounter'
  wait click 1

  send text '2) You can decrement the value of a counter'
  action decrement 'myCounter' by 20
  send text 'The new value of this counter: \$myCounter'
  wait click 1

  send text '3) You can set a counter to a value'
  action set 'myCounter' to 7
  send text 'The new value of this counter: \$myCounter'
  wait click 1

  send text '4) You can add new tags'
  action addTag 'pro-user'
  action addTag 'righteousness'
  action addTag 'full-of-grace'
  send text 'Current tags: \$tags'
  wait click 1

  send text '5) You can remove tags again'
  action removeTag 'pro-user'
  send text 'Current tags: \$tags'
  wait click 1

  send text '6) You clear all tags'
  action clearTags
  send text 'Current tags: \$tags'
  wait click 1

  send text 'More actions are planed. So stay tuned :)'
''',
  },
  {
    'name': 'Hello Conditions',
    'src': '''
create sender 'Laura B.'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
create counter 'myCounter'
set sender 'Laura B.'
set delay 700

flow 'main'
  send text 'I'
  send text 'am'
  send text 'infinite loop'
  action increment 'myCounter' by 5
  if counter 'myCounter' == 5
    send text 'High five!'
  if counter 'myCounter' > 0
    send text 'It´s a positive number too!'
  if counter 'myCounter' > 10
    send text 'It´s a big number (not)'
  else 
    send text 'It´s a small number'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
];
