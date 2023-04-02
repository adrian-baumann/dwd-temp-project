#!/bin/bash

# DESCRIPTION:
# TODO: ADD DESCRIPTION

# -------------------------------------------------------------
# -------------------------DOCKER------------------------------

# Update the apt package index and install packages to allow apt to use a repository over HTTPS
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 

# The following command is to set up the stable repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu `lsb_release -cs` stable" 

# Update the apt package index, and install the latest version of Docker Engine and container, or go to the next step to install a specific version
sudo apt update 
sudo apt install -y docker-ce

# Install docker compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# -------------------------------------------------------------
# ------------------------PROJECT------------------------------


# Clone project repo
git clone https://github.com/adrian-baumann/dwd-temp-project.git

# change directory
cd ./dwd-temp-project

# install dependencies, requirements.txt created from poetry.lock file
pip install -r requirements.txt

# build prefect-gcp block for use in deployement
python ./prefect_blocks.py

# run prefect server and agent in the background
source ./setup/prefect_server.sh &
source ./setup/prefect_agent.sh &

# configure server API
prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api

# build and apply deployment
prefect deployment build ./pipeline_web_to_gcs_bucket.py:etl_parent_flow \
--cron "*/1 * * * *"
-n "Web to GCS Flow" \
-o ./pipeline-deployment.yaml \
--apply

# run deployment
python ./prefect_run.py

# TODO: pre-commit hook for the following:
# poetry export -f requirements.txt -o requirements.txt --without-hashes