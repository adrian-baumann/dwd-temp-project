from prefect_gcp import GcpCredentials, GcsBucket, BigQueryWarehouse
from prefect.infrastructure import Process
import os

PROJECT_ID = os.environ["PROJECT_ID"]
PRIVATE_KEY = os.environ["PRIVATE_KEY"]
SERVICE_ACCOUNT_EMAIL = os.environ["SERVICE_ACCOUNT_EMAIL"]
CLIENT_ID = os.environ["CLIENT_ID"]
KEY_ID = os.environ["KEY_ID"]


def main() -> None:
    # add values in an .envrc or .env file with your own service account info
    # see here on how to create service account file:
    # https://cloud.google.com/iam/docs/keys-create-delete#creating
    service_account_info = {
        "type": "service_account",
        "project_id": f"{PROJECT_ID}",
        "private_key_id": f"{KEY_ID}",
        "private_key": f"{PRIVATE_KEY}",
        "client_email": f"{SERVICE_ACCOUNT_EMAIL}",
        "client_id": f"{CLIENT_ID}",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://accounts.google.com/o/oauth2/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": f"https://www.googleapis.com/robot/v1/metadata/x509/{SERVICE_ACCOUNT_EMAIL}",
    }

    GcpCredentials(service_account_info=service_account_info).save(
        "gcp-credentials-block", overwrite=True
    )

    local_storage_block = Process(working_dir=os.getcwd())
    local_storage_block.save("local-storage-block", overwrite=True)


if __name__ == "__main__":
    main()
