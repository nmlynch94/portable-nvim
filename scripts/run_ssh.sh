#!/bin/zsh

sudo su "${USERNAME}"
nvm install 20

sudo sshd -D &
SSH_PID=$!

echo "Started sshd with PID $SSH_PID"

trap "echo 'Received signal, stopping sshd...'; kill $SSH_PID; wait $SSH_PID" SIGTERM
wait
