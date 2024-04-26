#!/bin/bash

SERVER_FILE="server.js"  
APP_DIR="/home/unix/SERVERS/MindWave-Backend"  
DEPLOY_KEY="/home/unix/.ssh/bmw.pub"
GIT_CMD="git -C $APP_DIR" 
NPM_CMD="npm"  
NODE_CMD="node"  
BRANCH_NAME="production"
SECONDS_BETWEEN_CHECKS=30

eval "$(ssh-agent -s)"  
ssh-add $DEPLOY_KEY

if ! cd "$APP_DIR"; then
    echo "[!] UNABLE TO FIND APP_DIR!"
    exit 1
fi

$GIT_CMD fetch origin $BRANCH_NAME
$GIT_CMD checkout $BRANCH_NAME 

echo "[+] Starting NODE server"
$NODE_CMD $SERVER_FILE &
TASK_PID=$!

check_and_update() {
    $GIT_CMD fetch origin $BRANCH_NAME
    git_output=$($GIT_CMD pull)
    echo "[+] $git_output"

    if [[ ! "$git_output" =~ "Already up to date." ]]; then
        echo "[+] Killing current process"
        pkill $TASK_PID

        echo "[+] Pulling latest updates from $BRANCH_NAME"
        $GIT_CMD pull

        echo "[+] Installing NPM dependencies..."
        $NPM_CMD install --prefix $APP_DIR

        echo "[+] Starting NODE server"
        $NODE_CMD $SERVER_FILE &
        TASK_PID=$!
    fi
}

while true; do
    check_and_update
    sleep $SECONDS_BETWEEN_CHECKS
done
