#!/bin/bash
# run prefect agent
tmux new-session -d -s prefect-agent-session 'prefect agent start -q 'default' '