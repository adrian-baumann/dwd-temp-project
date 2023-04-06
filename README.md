# Problem Statement
I want to know specific daily aggregated meteorological indicators for all of germany in an arbitrary timeframe to feed into my not yet built "historical weather" app.

This pipeline enables me to built a mock-up of my app (--> dashboard). I would be able to more or less plug my app into the final tables in Bigquery.

# How To

## Prerequisites - GCS

1. You need to have a **gcloud account** and an **active project** with the following APIs enabled:
    - Compute Engine API
    - IAM Service Account Credentials API 
    - BigQuery API
    - Cloud Logging API
    - Identity and Access Management (IAM) API

2. You need to grant the following roles:
    - Service Account Token Creator,  BigQuery Admin,  BigQuery Resource Admin,  Compute Admin, Service Account User, Storage Admin, Storage Object Admin to service account
    - Service Account User to user running terraform (may be our gcloud user)


2. You need to have a **ssh-key pair** generated for gcloud virtual machines:<br>-->  https://cloud.google.com/compute/docs/instances/ssh#gcloud

3. You need to upload your ssh-key to compute engine --> metadata --> ssh keys to make ssh-ing to your vm easy.



## Prerequisites - Local
 1. Have this repo cloned to your local machine
 2. Have the following installed in your local machine:
    - Terraform
    - gcloud CLI
    - the python module `dbt-bigquery`
 3. after running `dbt init` inside [bigquery_dbt](./bigquery_dbt/), you also need to change the region inside the .dbt/profiles.yaml to `europe-west6` 

 4. Create an `.envrc` file in the projects' [root directory](./), copy-paste the following and replace the uppercase placeholders with your own information
    ```bash
    # copy-paste from service account info file (json file)
    export PROJECT_ID="<YOUR-PROJECT-ID>"
    export KEY_ID="<YOUR-SERVICE-ACCOUNT-KEY-ID>"
    export PRIVATE_KEY="-----BEGIN PRIVATE KEY-----<YOUR-SERVICE-ACCOUNT-PRIVATE-KEY>-----END PRIVATE KEY-----\n"
    export SERVICE_ACCOUNT_EMAIL="<YOUR-SERVICE-ACCOUNT-EMAIL>"
    export CLIENT_ID="<YOUR-CLIENT-ID>"
    ```
 5. Create a `terraform.tfvars` in the [terraform folder](./terraform/), copy-paste the following and replace the uppercase placeholders with your own information
    ```bash
    username                  = "<YOUR-GCLOUD-ACCOUNT-USERNAME>"
    region                    = "europe-west6"
    zone                      = "europe-west6-a"
    storage_class             = "STANDARD"
    BQ_DATASET                = "weather"
    data_lake_bucket          = "dwd_project"
    engine_private_key_file   = "~/.ssh/<YOUR-PRIVATE-GCLOUD-COMPUTE-SSH-KEY>"
    
    PROJECT_ID                = "<YOUR-PROJECT-ID>"
    KEY_ID                    = "<YOUR-SERVICE-ACCOUNT-KEY-ID>"
    PRIVATE_KEY               = "-----BEGIN PRIVATE KEY-----<YOUR-SERVICE-ACCOUNT-PRIVATE-KEY>-----END PRIVATE KEY-----\n"
    SERVICE_ACCOUNT_EMAIL     = "<YOUR-SERVICE-ACCOUNT-EMAIL>"
    CLIENT_ID                 = "<YOUR-CLIENT-ID>"
    ```

# Execution

1. Run terraform
    ```bash
    terraform apply
    ```
2. ssh to vm
    ```bash
    gcloud compute ssh --zone "europe-west6-a" "dwd-project-vm"  --project "<YOUR-PROJECT-ID>"
    ```
3. Run `setup.sh` and accept everything. If not executable, run `chmod +x setup.sh` and try again.<br>This script will run about 15-20 mins and will
    1. download and install direnv and pip3
    2. clone the project repo
    3. download python packages via requirements.txt
    4. set prefect blocks
    5. start up prefect agent and server in their own tmux terminals
    6. run a prefect deployment build/apply to update the deployment yaml
    7. run the deployment

## The prefect deployment
This script will
1. download dwd daily aggregated data onto your vm
    - source: [dwd opendata](https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/)
2. transform the data
    - rename stuff
    - trim spaces
    - enforce the correct datetype
3. save data in a partitioned parquet format
4. load partitioned data into the `dwd_project` bucket in Google Cloud.Storage
5. built a BigQuery table using the parquet data in Google Cloud Storage.

## dbt
After the prefect flow finished, you can `exit` the vm and `cd` into [bigquery_dbt](./bigquery_dbt/). 
In line 6 in [models/staging/schema.yml](./bigquery_dbt/models/staging/schema.yml) change the `database` to your own project_id.

Now you can run `dbt deps`, `dbt seed` and `dbt run`.
You can also checkout the docs if you want.

## Dashboard
You can see [my Dashboard here](https://lookerstudio.google.com/reporting/e3568dcc-c62c-4178-8d8d-1ac4b587dbc4).
