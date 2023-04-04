# How To

## Prerequisites - GCS

1. You need to have a **gcloud account** and an **active project** with the following APIs enabled:
    - Compute Engine API
    - IAM Service Account Credentials API 
    - BigQuery API
    - Secret Manager API
    - Cloud Logging API ?
    - Cloud Resource Manager API ?
    - Service Usage API 
    - Identity and Access Management (IAM) API ?

2. You need to have a **ssh-key pair** generated for gcloud virtual machines:<br>-->  https://cloud.google.com/compute/docs/instances/ssh#gcloud

3. Create an `.envrc` file in the projects' [root directory](./), copy-paste the following and replace the uppercase placeholders with your own information
    ```bash
    # For usage of spark
    export JAVA_HOME="${HOME}/spark/jdk-17.0.2"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    export SPARK_HOME="${HOME}/spark/spark-3.3.2-bin-hadoop3"
    export PATH="${SPARK_HOME}/bin:${PATH}"
    export PYTHONPATH="${SPARK_HOME}/python/:$PYTHONPATH"
    export PYTHONPATH="${SPARK_HOME}/python/lib/py4j-0.10.9.5-src.zip:$PYTHONPATH"

    # EDIT BEGIN 
    # copy-paste from service account info file (json file)
    export PROJECT_ID="<YOUR-PROJECT-ID>"
    export KEY_ID="<YOUR-SERVICE-ACCOUNT-KEY-ID>"
    export PRIVATE_KEY="-----BEGIN PRIVATE KEY-----<YOUR-SERVICE-ACCOUNT-PRIVATE-KEY>-----END PRIVATE KEY-----\n"
    export SERVICE_ACCOUNT_EMAIL="<YOUR-SERVICE-ACCOUNT-EMAIL>"
    export CLIENT_ID="<YOUR-CLIENT-ID>"
    # EDIT END

    # misceleanous, change to your preferences
    export BUCKET_NAME="dwd-temp-daily" # name of the storage bucket
    ```
4. Create a `terraform.tfvars` in the [terraform folder](./terraform/), copy-paste the following and replace the uppercase placeholders with your own information
    ```bash
    username                  = "<YOUR-GCLOUD-ACCOUNT-USERNAME>"
    project                   = "<YOUR-PROJECT-ID>"
    region                    = "europe-west6"
    zone                      = "europe-west6-a"
    storage_class             = "STANDARD"
    BQ_DATASET                = "temperatures"
    data_lake_bucket          = "dwd_project"
    terraform_service_account = "<YOUR-SERVICE-ACCOUNT-EMAIL>"
    engine_private_key_file   = "~/.ssh/<YOUR-PRIVATE-GCLOUD-COMPUTE-SSH-KEY>"
    ```
## Prerequisites - Local
 1. Have this repo cloned 
 2. Have the following installed:
    - Terraform
    - gcloud CLI

# Setup

## Prefect

#TODO: Add stuff from envrc to this part

### Blocks
With GCS:
```bash
prefect block register -m prefect_gc
```
1. Add service accout credentials to credentials block
2. Add credentials block to bucket block

### Deployment code

```bash
prefect deployment build ./pipeline_web_to_gcs_bucket.py:etl_parent_flow \
--cron "*/1 * * * *"
-n "Web to GCS Flow" \
-o ./pipeline-deployment.yaml \
--apply
```

`-n`: deployment name \
`-sb`: storage block, refers to the created github block. Also, appending subfolders is possible \
`-o` : output, location and filename \
`--apply` : saves and updates deployment in prefect orion/cloud

# Run everything

1. Run terraform
    ```bash
    terraform apply
    ```
2. ssh to vm
#TODO: add correct info below
```bash
gcloud compute ssh --zone "europe-west6-a" "test"  --project "dtc-de-zoomcamp-376519"
```
3. Run `setup.sh` and accept everything. If not executable, run `chmod +x setup.sh` and try again.<br>This script will run about 15-20 mins and will
    1. download and install direnv and pip3
    2. clone the project repo
    3. download python packages via requirements.txt
    4. set prefect blocks
    5. start up prefect agent and server in their own tmux terminals
    6. run a prefect deployment build/apply to update the deployment yaml
    7. run the deployment, which will:  

### The prefect deployment
This script will
    1. download data onto your vm
    2. 