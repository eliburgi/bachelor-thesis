/// Source codes of multiple sample programs.
const List<Map<String, dynamic>> SAMPLE_PROGRAMS = [
  {
    'name': 'Hello World',
    'src': '''
set delay 700
flow 'main'
  send text 'Hello World'
  send text 'You can program me however you like.'
''',
  },
  {
    'name': 'Send Statement',
    'src': '''
set delay 700
flow 'main'
  send text 'Obviously, you can send text messages.'
  send text 'You can also send images.'
  send image 'https://picsum.photos/200'
  send text 'And audio too.'
  send audio 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
''',
  },
  {
    'name': 'Hello Event',
    'src': '''
set delay 700
flow 'main'
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
    'name': 'Single Choice Input',
    'src': '''
create sender 'Laura B.'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
set sender 'Sarah P.'
set delay 700

flow 'main'
  send text 'Hello'
  send text 'What is your favorite color?'
  input singleChoice
    choice 'green'
      send text 'Sounds like you are a nature person.'
    choice 'orange'
      send text 'You like pumpkins.'
    choice 'yellow'
      send text 'You are so bright :)'
  startFlow 'loop'

flow 'loop'
  send text 'Oh really?'
  startFlow 'main'
''',
  },
  {
    'name': 'Free Text Input',
    'src': '''
set delay 700

flow 'main'
  send text 'You can ask the user to enter some text.'
  send text 'For example, I could ask you what´s your favorite sport?'
  input freeText
    when 'soccer', 'basketball', 'tennis' respond 'ball-sport'
    when 'swimming', 'running', 'biking' respond 'triathlon'
    response 'ball-sport'
      send text 'Yeah, who doesn´t like ball sports. Seriously.'
    response 'triathlon'
      send text 'Great.'
      send text 'It takes a lot of endurance to get good at \$userInputText'
    fallback
      send text 'Ohh I did not think about \$userInputText'
      send text 'But I´m sure it´s a great sport too.'
''',
  },
  {
    'name': 'Echo',
    'src': '''
set delay 700
flow 'main'
  send text 'Type quit to exit.'
  startFlow 'loop'

flow 'loop'
  input freeText
    when 'quit' respond 'quit'
    response 'quit' 
      endFlow
  send text '\$userInputText'
  startFlow 'loop'
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
create sender 'John Doe'
  avatarUrl = 'https://picsum.photos/id/1011/300/300'
create counter 'myCounter'
set sender 'John Doe'
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
  {
    'name': 'Order Pizza',
    'src': '''
create sender 'Buenos Pizzas'
  avatarUrl = 'https://image.freepik.com/vektoren-kostenlos/pizza-logo-design-vektor-vorlage_260747-60.jpg'
set sender 'Buenos Pizzas'
set delay 700

flow 'main'
  send text 'Welcome at Buenos Pizzas. What would you like to order?'
  input singleChoice
    choice 'Pizza'
      startFlow 'order-pizza'
      startFlow 'goodbye'
    choice 'Nothing'
      startFlow 'goodbye'
      endFlow

flow 'order-pizza'
  send text 'Which Pizza would you like?'
  input freeText
    when 'Salami', 'salami' respond 'choose-salami'
    when 'Margarita', 'margarita' respond 'choose-margarita'
    when 'Veggie', 'veggie' respond 'choose-veggie'
    response 'choose-salami'
      send text 'Good choice. We use organic salami.'
      send text 'Here is a picture of our salami pizza.'
      send image 'https://ais.kochbar.de/kbrezept/44326_17343/1200x1200/pizza-salami-rezept.jpg'
      action addTag 'salami' 'pizza-type'
    response 'choose-margarita'
      send text 'Good choice.'
      send text 'Here is a picture of our margarita pizza.'
      send image 'https://img2.kochrezepte.at/use/1/pizza-margherita-auf-die-schnelle-art_1192.jpg'
      action addTag 'margarita' 'pizza-type'
    response 'choose-veggie'
      send text 'Good choice. The world should eat more veggies anyway.'
      send text 'Here is a picture of our veggie pizza.'
      send image 'https://lifeisfullofgoodies.com/wp-content/uploads/2017/06/9-1-1.jpg'
      action addTag 'veggie' 'pizza-type'
    fallback 
      send text 'Sorry, we don´t have this pizza.'
      startFlow 'order-pizza'
      endFlow
 
  send text 'Now enter the size of your pizza.'
  input singleChoice
    choice 'normal'
      action addTag 'normal' 'pizza-size'
    choice 'large'
      action addTag 'large' 'pizza-size'
  
  send text 'Please enter your delivery address.'
  input freeText
    when 'Why do you need it?' respond 'help'
    response 'help'
      send text 'We need your address to deliver your pizza to you :)'
  action addTag '\$userInputText' 'address'
  
  send text 'Ok. So you want to order a \$pizza-size \$pizza-type pizza to \$address ?'  
  input singleChoice
    choice 'Yes'
      send text 'Perfect. We notify you when the pizza is baked.'
    choice 'Cancel'
      send text 'No problem, we´ve cancelled your order.'
      endFlow
  wait event 'pizza-ready-for-delivery'
  send text 'Your pizza is ready and will now be delivered to you.'
  send text 'Enjoy the meal :)'

flow 'goodbye'
  send text 'Have a nice day! Bye.'
''',
  },
  {
    'name': 'Austria FAQ',
    'src': '''
create counter 'questions-asked'

create sender 'Oetzi'
  avatarUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Flag_of_Austria.svg/255px-Flag_of_Austria.svg.png'
set sender 'Oetzi'

set delay 1500

flow 'main'
  send text 'Hello I am Oetzi, an Austria Bot.'
  send text 'I can answer common questions about Austria.'
  send text 'You can ask me about food or sports.'
  startFlow 'ask-me'
  send text 'You have asked me \$questions-asked questions.'
  send text 'I am glad I could help you.'
  send text 'Have a good day. Bye :)'

flow 'ask-me'
  send text 'What would you like to know?'
  input freeText
    when '[.]*soccer|football|sv-ried[.]*' respond 'sport-soccer'
    when '[.]*ski|skiing|snow|sport[.]*' respond 'sport-ski'
    when '[.]*food|foods|eat|eating|kitchen|cuisine[.]*' respond 'food'
    response 'sport-soccer'
      send text 'Austria is decent at soccer.'
      send text 'In 1978 Austria even managed to get under the best 8 teams in the world finals.'
    response 'sport-ski'
      send text 'Ahh skiing. This is Austria´s signatur sport discipline.'
      send text 'Great names such as Hermann Maier and Marcel Hirscher are from Austria.'
      send text 'But many locals enjoy skiing just as much as the pros.'
      send image 'https://mogasimagazin.com/wp-content//uploads/2019/09/skigebiet-kappl-2019-3.jpg'
    response 'food'
      send text 'Ahh food. You´ve probably heard of the Wiener Schnitzel right?'
      send image 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Wiener-Schnitzel02.jpg'
      send text 'And the sweets. Austrian people love their sweet cakes.'  
      send text 'You gotta try Sachertorte or Apfelstrudel once. It´s so good.'
    fallback
      send text 'Sorry I do not understand this question.'
  action increment 'questions-asked' by 1
   
  send text 'Do you have another question?'
  input singleChoice
    choice 'Yes'
      startFlow 'ask-me'
    choice 'No'
      endFlow
''',
  },
  {
    'name': 'Computer Science Quiz',
    'src': '''
create counter 'points'
create sender 'A. Turing'
set sender 'A. Turing'
set delay 900

flow 'main'
  action set 'points' to 0
  send text 'How much do you know about Computer Science? Find out now!'
  send text 'Are you ready?'
  input singleChoice
    choice 'Yes'
      send text 'Let´s begin!'
    choice 'No'
      send text 'No problem. See you later.'
      endFlow
  send text '1) Linux is ...'
  input singleChoice
    choice 'a browser'
      send text 'Wrong. Linux is an operating system.'
    choice 'an operating system'
      action addTag 'q1'
      action increment 'points' by 10
      send text 'Correct!'
    choice 'an app'
      send text 'Wrong. Linux is an operating system.'
  send text 'You have \$points points'
  send text '2) Ruby is the name of a programming language.'
  input singleChoice
    choice 'True'
      action addTag 'q2'
      action increment 'points' by 10
      send text 'Correct!'
    choice 'False'
      send text 'Wrong. Ruby is indeed the name of a popular programming language.'
  send text 'You have \$points points'
  send text 'Last question.'
  send text '3) What is the name of the first chatbot ever?'
  input singleChoice
    choice 'ELIZA'
      action addTag 'q3'
      action increment 'points' by 10
      send text 'Correct! It was developed 1966 at the MIT.'
    choice 'MATRIX'
      send text 'Wrong. The first chatbot was developed 1966 at the MIT and was called ELIZA.'
    choice 'ALEXA'
      send text 'Wrong. The first chatbot was developed 1966 at the MIT and was called ELIZA.'
  send text 'You have \$points points'
  if counter 'points' == 30
    send text 'Awesome, all questions were correct. You´re a CS pro!'
  if counter 'points' == 20
    send text 'Not too bad. Two out of three.'
  if counter 'points' == 10
    send text 'One out of three. You´re not a very techy person right?'
  if counter 'points' == 0
    send text 'Well done. You´ve answered everything wrongly.'
    send text 'That´s almost as hard as answering everything correctly.'
    send text 'You could be a hidden genius ...'
  send text 'Anyway, thanks for playing.'
  send text 'Feel free to add your own questions and share them with your friends.'
  send text 'You sure have a better humor than I do, haha :P'
''',
  },
];
