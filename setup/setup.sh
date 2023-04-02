#!/bin/bash

# DESCRIPTION:
# TODO: ADD DESCRIPTION

# ----------------------------------------------------------------

# DOCKER

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

# ----------------------------------------------------------------

# ----------------------------------------------------------------

# PROJECT

# Clone project repo
git clone https://github.com/adrian-baumann/dtc-de-zoomcamp.git

cd ./dtc-de-zoomcamp/week7/requirements.txt

pip install -r requirements.txt


# TODO: pre-commit hook for the following:
# poetry export -f requirements.txt -o requirements.txt --without-hashes