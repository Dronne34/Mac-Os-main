#!/bin/bash

SESSION="my_session"

# Verifică dacă sesiunea există
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    # Creează sesiunea cu un singur panou (implicit 0)
    tmux new-session -d -s $SESSION

    # Împarte panoul 0 pe orizontal, creează panoul 1 (dreapta), 50%
    tmux split-window -h -p 35 -t $SESSION:0.0

    # Acum panoul 1 e în dreapta, îl împărțim vertical (sus și jos)
    tmux split-window -v -p 65 -t $SESSION:0.1

    # Selectăm panoul mare stânga (panoul 0)
    tmux select-pane -t $SESSION:0.0
fi

# Atașează sesiunea
tmux attach-session -t $SESSION
