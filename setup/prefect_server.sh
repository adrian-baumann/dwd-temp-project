#!/bin/bash
# run prefect server
tmux new-session -d -s prefect-server-session 'prefect server start'