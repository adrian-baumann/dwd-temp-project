from prefect.deployments import run_deployment


def main():
    response = run_deployment(
        name="ETL_Parent_Flow/Web to GCS Flow", parameters={"download_data": False}
    )
    print(response)


if __name__ == "__main__":
    main()
