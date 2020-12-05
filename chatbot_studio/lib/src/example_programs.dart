/// Source codes of multiple sample programs.
const List<Map<String, dynamic>> EXAMPLE_PROGRAMS = [
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
];
