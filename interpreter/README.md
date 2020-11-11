# Interpreter for the Chatbot Conversation Modelling Language (CCML) 

## Goals of this bachelor thesis

## Language Grammar

program = [declarations] main_flow [flows] EOF.

declarations = (create_stmt | set_stmt) NEWLINE {(create_stmt | set_stmt) NEWLINE}
main_flow = 'flow' '\''main'\'' block.
flows = flow_stmt NEWLINE {flow_stmt NEWLINE}

statement =
    | set_stmt
    | startflow_stmt
    | endflow_stmt
    | send_stmt
    | wait_stmt
    | input_stmt
    | if_stmt
    .
statements = statement NEWLINE {statement NEWLINE}.
block = NEWLINE INDENT statements DEDENT.

params = NEWLINE INDENT param {param} DEDENT
param = NAME '=' param_value NEWLINE
param_value = STRING | INTEGER

create_stmt = 'create' entity [params].
entity =
    | 'sender' STRING
    | 'counter' STRING
    .

set_stmt = 'set' config_property
config_property =
    | 'delay' ('dynamic' | INTEGER)
    | 'sender' STRING
    .

flow_stmt = 'flow' STRING block.
startflow_stmt = 'startFlow' STRING.
endflow_stmt = 'endFlow'.

send_stmt = 'send' message [params].
message =
    | 'text' STRING
    | 'image' STRING
    | 'audio' STRING
    | 'event' STRING
    .

wait_stmt = 'wait' trigger.
trigger =
    | 'delay' INTEGER
    | 'click' INTEGER
    | 'event' STRING
    .

action_stmt = 'action' action_type.
action_type =
    | 'increment' STRING 'by' INTEGER
    | 'decrement' STRING 'by' INTEGER
    | 'set' STRING 'to' INTEGER
    | 'addTag' STRING
    | 'removeTag' STRING
    | 'clearTags'
    .

input_stmt = 'input' input_type.
input_type =
    | 'singleChoice' choices
    .
choices = NEWLINE INDENT choice {choice} DEDENT.
choice = 'choice' STRING block.

if_stmt = 'if' cond block ['else' block].
cond =
    | 'counter' STRING cond_op INTEGER
    | 'hasTag' STRING
    .
cond_op = '<' | '<=' | '>' | '>=' | '=='.
