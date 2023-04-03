#!/bin/bash

# DESCRIPTION:
# TODO: ADD DESCRIPTION

# -------------------------------------------------------------
# -------------------------DOCKER------------------------------

# Update the apt package index and install packages to allow apt to use a repository over HTTPS
# sudo apt update
# sudo apt install apt-transport-https ca-certificates curl software-properties-common

# # Add Docker’s official GPG key
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 

# # The following command is to set up the stable repository
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu `lsb_release -cs` stable" 

# # Update the apt package index, and install the latest version of Docker Engine and container, or go to the next step to install a specific version
# sudo apt update 
# sudo apt install -y docker-ce

# # Install docker compose
# sudo apt-get update
# sudo apt-get install docker-compose-plugin

# Install direnv
sudo apt-get update
sudo apt-get install direnv
eval "$(direnv hook bash)"

# Install pip3
sudo apt update
sudo apt install python3-pip


# -------------------------------------------------------------
# ------------------------PROJECT------------------------------

# some env vars
export BUCKET_NAME="dwd-temp-daily" # name of the storage bucket


# Clone project repo
git clone https://github.com/adrian-baumann/dwd-temp-project.git

mv ./.envrc ./dwd-temp-project/ 
# change directory and direnv allow
cd ./dwd-temp-project

# Make sure your bin is in the PATH
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:${PATH}"
[[ ":$PATH:" != *":$HOME/$USER/.local/bin:"* ]] && PATH="$HOME/$USER/.local/bin:${PATH}"

# Source envs
source ./.envrc
direnv allow

# install dependencies, requirements.txt created from poetry.lock file
pip3 install -r requirements.txt

# build prefect-gcp block for use in deployement
python3 ./prefect_blocks.py

# run prefect server and agent in the background
source ./setup/prefect_server.sh 
source ./setup/prefect_agent.sh

# configure server API
prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api

# build and apply deployment
# schedule to run this deployment at 04:00 in the morning every day
prefect deployment build ./pipeline_web_to_gcs_bucket.py:etl_parent_flow \
--cron "* 4 * * *"
-n "Web to GCS Flow" \
-o ./pipeline-deployment.yaml \
--apply

# run deployment
python3 ./prefect_run.py

# TODO: pre-commit hook for the following:
# poetry export -f requirements.txt -o requirements.txt --without-hashes