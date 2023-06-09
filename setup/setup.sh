#!/bin/bash
Color='\033[1;33m' # bold yellow
Color_Off='\033[0m'


# DESCRIPTION:
# When your run this script (from your vms root) it will do the following:
# 1. download and install direnv and pip3
# 2. clone the project repo
# 3. download python packages via requirements.txt
# 4. set prefect blocks
# 5. start up prefect agent and server in their own tmux terminals
# 6. run a prefect deployment build/apply to update the deployment yaml
# 7. run the prefect deployment  

# -------------------------------------------------------------
# --------------------SUDO-INSTALLS----------------------------

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
export BUCKET_NAME="dwd_project" 
export DATASET_NAME="weather" 
export DATASET_LOCATION="europe-west6" 


# Clone project repo
git clone https://github.com/adrian-baumann/dwd-temp-project.git

mv ./.envrc ./dwd-temp-project/ 
cp ./data/final/metadata_geo.csv ./bigquery_dbt/seeds/
cp ./data/final/metadata_operator.csv ./bigquery_dbt/seeds/
# change directory and direnv allow
NOW=$(date +"%H:%M:%S")
echo -e "$NOW  --  Changing working directory to local clone of git repo${Color_Off}"
cd ./dwd-temp-project

# Make sure your bin is in the PATH
NOW=$(date +"%H:%M:%S")
echo -e "${Color}$NOW  --  Adding paths to PATH env variable.${Color_Off}"
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:${PATH}"
[[ ":$PATH:" != *":$HOME/$USER/.local/bin:"* ]] && PATH="$HOME/$USER/.local/bin:${PATH}"

# Source envs
source ./.envrc
direnv allow

# install dependencies, requirements.txt created from poetry.lock file
NOW=$(date +"%H:%M:%S")
echo -e "${Color}$NOW  --  Installing python3 dependencies.${Color_Off}"
pip3 install -r requirements.txt
prefect block register -m prefect_gcp

# build prefect-gcp block for use in deployement
NOW=$(date +"%H:%M:%S")
echo -e "${Color}$NOW  --  Creating prefect blocks for usage in flow.${Color_Off}"
python3 ./prefect_blocks.py

# run prefect server and agent in the background
NOW=$(date +"%H:%M:%S")
echo -e "${Color}$NOW  --  Starting up prefect server and agent.${Color_Off}"
source ./setup/prefect_server.sh 
source ./setup/prefect_agent.sh

# configure server API
prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api

# build and apply deployment
# schedule to run this deployment at 04:00 in the morning every day
NOW=$(date +"%H:%M:%S")
echo -e "${Color}$NOW  --  Building prefect deployment.${Color_Off}"
prefect deployment build ./pipeline_web_to_gcs_bucket.py:etl_parent_flow \
--cron "0 4 * * *" \
--timezone 'Europe/Berlin' \
-ib process/local-storage-block \
-n "Web to GCS Flow" \
-o ./pipeline-deployment.yaml \
--apply

# run deployment
NOW=$(date +"%H:%M:%S")
echo -e "${Color}$NOW  --  Starting prefect flow. To view progress, run 'tmux a' in separate vm terminal.${Color_Off}"
echo -e "${Color}$NOW  --  Please be patient. Flow run will take about ~20 minutes.${Color_Off}"
python3 ./prefect_run.py

NOW=$(date +"%H:%M:%S")
echo -e "${Color}${NOW}  --  Finished flow run.${Color_Off}"


# TODO: pre-commit hook for the following:
# poetry export -f requirements.txt -o requirements.txt --without-hashes