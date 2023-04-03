import re
import os, sys
from pathlib import Path
import pandas as pd
import pyarrow as pa
from prefect import flow, task
from prefect_gcp.cloud_storage import GcsBucket
from random import randint
from prefect.tasks import task_input_hash
from datetime import timedelta

from time import sleep
import itertools
import requests
from bs4 import BeautifulSoup
from zipfile import ZipFile

import gc


@task(
    name="Get-File_links",
    task_run_name="Get-{category}-files",
    description="Returns links to files from endpoint of the DWD Opendata website.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
    retries=1,
)
def get_file_links(url: str, category: str) -> list:
    """Get urls of files"""
    tmp_url = url + category
    page = requests.get(tmp_url)
    soup = BeautifulSoup(page.content, "html.parser")
    links = soup.find_all("a", href=re.compile(".pdf$|.txt$|.zip$"))
    print("found {} files for download".format(len(links)))

    return [[link, category] for link in links]


@task(
    name="Download-Files",
    task_run_name="download-{link_and_category[1]}-files",
    description="Downloads compressed files from two endpoints of the DWD Opendata website.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
    retry_delay_seconds=20,
    retries=5,
)
def download_files(url: str, link_and_category: list) -> None:
    """
    Download daily mean of the observed air temperatures at 2m height above ground from DWD (German Meteorological Service).
    Loading can take some time as it is intentionally slowed down to decrease load on opendata server.
    """

    link, category = link_and_category

    save_path = Path(f"./data/{category}/download")
    save_path.mkdir(parents=True, exist_ok=True)

    file_path = save_path / link["href"]
    mode = "w+b" if "pdf" or "zip" in link["href"] else "w+"
    file_url = url + link["href"]
    if not file_path.is_file():
        with requests.get(file_url) as response:
            with open(str(file_path), mode) as file:
                file.write(response.content)
                sleep(0.5)
    # TODO: add error handler for timeout with too many requests


@task(
    name="Unzip-Files",
    task_run_name="unzip-{category}-files",
    description="Unzips txt files from compressed files and saves them according to data type.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
)
def unzip(category: str) -> None:
    """
    Unzip all (meta-)data to their respective folders under data:
    - temperature tables \t-> ./data/<type of data>/tables
    - metadata tables \t-> ./data/<type of data>/metadata
    """

    path = Path(f"data/{category}/")
    source_path = path / "download"
    source_path.mkdir(parents=True, exist_ok=True)
    target_data_path = path / "tables"
    target_data_path.mkdir(parents=True, exist_ok=True)
    target_metadata_path = path / "metadata"
    target_metadata_path.mkdir(parents=True, exist_ok=True)

    for file in source_path.glob("*.zip"):
        with ZipFile(file, "r") as zip:
            fname_data_lst = [
                fname for fname in zip.namelist() if "produkt_klima_tag" in fname
            ]
            fname_metadata_lst = [
                fname for fname in zip.namelist() if "Metadaten" in fname
            ]
            for fname in fname_data_lst:
                zip.extract(fname, target_data_path)
            for fname in fname_metadata_lst:
                zip.extract(fname, target_metadata_path)

    files_to_rmv = target_metadata_path.glob("*.html")
    if files_to_rmv:
        for file in files_to_rmv:
            file.unlink()

    print("finished unzipping to folder {}".format(path))


@task(
    name="Fetch-Datasets",
    task_run_name="load-{df_name}-dataset",
    description="Loads DataFrames from .txt-files into memory.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
)
def fetch_dataset(df_name: str) -> (pd.DataFrame, str()):
    """Reads in datasets by creating lists of small dataframes and concatenating them"""
    print(f"loading {df_name} dataset into a pandas dataframe")
    if df_name == "main":
        dtypes = {
            "STATIONS_ID": "string",
            "QN_3": "UInt8",
            "QN_4": "UInt8",
            " RSK": "Float32",
            "RSKF": "UInt8",
            "SHK_TAG": "UInt8",
            "  NM": "string",
            " TMK": "Float32",
            " UPM": "Float32",
            " TXK": "Float32",
            " TNK": "Float32",
            " TGK": "Float32",
        }
        paths = {
            "recent": Path("./data/recent/tables"),
            "historical": Path("./data/historical/tables"),
        }
        usecols = [
            "STATIONS_ID",
            "MESS_DATUM",
            "QN_3",
            "QN_4",
            " RSK",
            "RSKF",
            "SHK_TAG",
            "  NM",
            " TMK",
            " UPM",
            " TXK",
            " TNK",
            " TGK",
        ]

        df_new_lst = [
            pd.read_table(
                file,
                sep=";",
                usecols=usecols,
                dtype_backend="pyarrow",
                dtype=dtypes,
                na_values=None,
            )
            for file in paths["recent"].glob("*.txt")
        ]

        df_hist_lst = [
            pd.read_table(
                file,
                sep=";",
                usecols=usecols,
                dtype_backend="pyarrow",
                dtype=dtypes,
                na_values=None,
            )
            for file in paths["historical"].glob("*.txt")
        ]
        df = pd.concat(df_new_lst + df_hist_lst).reset_index(drop=True)
        df = df.replace(-999, None).astype(dtypes)

    if df_name == "metadata_geo":
        dtypes = {
            "Stations_id": "string",
            "Stationshoehe": "Float32",
            "Geogr.Breite": "Float32",
            "Geogr.Laenge": "Float32",
            "von_datum": "string",
            "bis_datum": "string",
            "Stationsname": "string",
        }

        df_new_lst = [
            pd.read_table(
                file,
                sep=";",
                encoding="latin1",
                dtype=dtypes,
                dtype_backend="pyarrow",
                na_values=None,
            )
            for file in Path("./data/recent/metadata").glob("Metadaten_Geographie*")
        ]

        df_hist_lst = [
            pd.read_table(
                file,
                sep=";",
                encoding="latin1",
                dtype=dtypes,
                dtype_backend="pyarrow",
                na_values=None,
            )
            for file in Path("./data/historical/metadata").glob("Metadaten_Geographie*")
        ]

        df = pd.concat(df_new_lst + df_hist_lst).reset_index(drop=True)
        df = df.replace(-999, None).astype(dtypes)

    if df_name == "metadata_operator":
        df_new_lst = []
        for file in Path("./data/recent/metadata").glob(
            "Metadaten_Stationsname_Betreibername*"
        ):
            with open(file, "r", encoding="latin1") as txt_file:
                text = txt_file.read()
                table_with_footer = text.split(
                    "\n\nStations_ID;Betreibername;Von_Datum;Bis_Datum\n "
                )[1]
                df_new_lst += [
                    line.split(";") for line in table_with_footer.splitlines()[:-1]
                ]

        df = pd.DataFrame(
            df_new_lst,
            columns=[
                "stations_id",
                "betreibername",
                "betrieb_von_datum",
                "betrieb_bis_datum",
            ],
        )

    return df


@task(
    name="Transform",
    task_run_name="transform-{df_name}-dataframe",
    description="Transforms dates to correct format and other small changes.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
    cache_key_fn=task_input_hash,
    cache_expiration=timedelta(days=1),
)
def transform(df: pd.DataFrame, df_name: str) -> pd.DataFrame:
    """Fix dtype issues"""

    if df_name == "main":
        df["MESS_DATUM"] = pd.to_datetime(
            df["MESS_DATUM"], format="%Y%m%d", errors="coerce", utc=False
        ).dt.tz_localize("Europe/Brussels", ambiguous="NaT", nonexistent="NaT")
    if df_name == "metadata_geo":
        df["Stations_id"] = df["Stations_id"].str.replace(" ", "")
        df["von_datum"] = pd.to_datetime(
            df["von_datum"], format="%Y%m%d", errors="coerce", utc=False
        ).dt.tz_localize("Europe/Brussels", ambiguous="NaT")
        df["bis_datum"] = pd.to_datetime(
            df["bis_datum"], format="%Y%m%d", errors="coerce", utc=False
        ).dt.tz_localize("Europe/Brussels", ambiguous="NaT")
    if df_name == "metadata_operator":
        df["stations_id"] = df["stations_id"].str.replace(" ", "")
        df["betrieb_von_datum"] = pd.to_datetime(
            df["betrieb_von_datum"], format="%Y%m%d", errors="coerce", utc=False
        ).dt.tz_localize("Europe/Brussels", ambiguous="NaT")
        df["betrieb_bis_datum"] = pd.to_datetime(
            df["betrieb_bis_datum"], format="%Y%m%d", errors="coerce", utc=False
        ).dt.tz_localize("Europe/Brussels", ambiguous="NaT")
    df.columns = df.columns.str.replace(" ", "")
    df.columns = [col_name.lower() for col_name in df.columns]
    print(f"rows: {len(df)}")
    return df


@task(
    name="Write-to-Local",
    task_run_name="save-{df_name}-dataframe-as-parquet",
    description="Write DataFrame out locally as parquet file.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
    cache_key_fn=task_input_hash,
    cache_expiration=timedelta(days=1),
)
def write_local(df: pd.DataFrame, df_name: str) -> Path:
    """Write DataFrame out locally as parquet file"""
    path = Path(f"./data/parquet/{df_name}.parquet")
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(path, compression="gzip")
    return path


@task(
    name="Write-to-GCS",
    task_run_name="upload-{path}",
    description="Writes local data to Google Cloud Storage using the GCSBucket Block.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
    timeout_seconds=600,
)
def write_gcs(path: Path) -> None:
    """Upload local parquet file using `path` object to GCS"""
    gcs_block = GcsBucket.load("gcs-dtc-bucket")
    gcs_block.upload_from_path(from_path=path, to_path=path, timeout=600)
    return


@flow(
    name="ETL_Web-to-Local",
    flow_run_name="download-{category}-files",
    description="Downloads and unzips files from DWD Opendata website.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
)
def etl_web_to_local(category: str) -> Path:
    """The main E function"""
    url = "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/"
    links_and_categories = get_file_links(url, category)
    num_links = len(links_and_categories)

    # Downloading starts here
    for count, link_and_category in enumerate(links_and_categories):
        download_files(url, link_and_category)
        print(f"downloads finished: {count}/{num_links}")
    unzip(category)


@flow(
    name="ETL_Transform_Write",
    flow_run_name="transform-{df_name}-dataset",
    description="Transforms and saves dataset to parquet-file.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
)
def etl_transform_write(df_name: str) -> Path:
    """The main T function"""

    df = fetch_dataset(df_name)
    df = transform(df, df_name)
    path = write_local(df, df_name)

    return path


@flow(
    name="ETL_Local_to_GCloud_Storage",
    flow_run_name="upload-to-{path}",
    description="Writes local data to Google Cloud Storage using the GCSBucket Block.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
)
def etl_local_to_gcs(path: Path) -> None:
    """The main L function"""
    write_gcs(path)


@flow(
    name="ETL_Parent_Flow",
    flow_run_name="orchestrate-child-flows",
    description="Creates flows handling the download, unpacking, transforming, saving and uploading.",
    version=os.getenv("GIT_COMMIT_SHA"),
    log_prints=True,
)
def etl_parent_flow(
    dataset_categories: list[str] = ["historical", "recent"],
    df_names: list[str] = ["main", "metadata_geo", "metadata_operator"],
    download_data: bool = False,
) -> None:
    paths = []
    if download_data:
        for category in dataset_categories:
            etl_web_to_local(category)
    for df_name in df_names:
        paths.append(etl_transform_write(df_name))
    for path in paths:
        try:
            etl_local_to_gcs(path)
        except OSError:
            print(f"Connection Timeout. Try uploading manually.\nFile: {path.name}")

        else:
            print("parameter is missing")


if __name__ == "__main__":
    dataset_categories = ["historical", "recent"]
    df_names = ["main", "metadata_geo", "metadata_operator"]
    download_data = False
    etl_parent_flow(dataset_categories, df_names)
