terraform {
  required_version = ">= 1.4.4"
  backend "local" {} # Can change from "local" to "gcs" (for google) or "s3" (for aws), if you would like to preserve your tf-state online
  required_providers {
    google = {
      source = "hashicorp/google"

    }
  }
}

provider "google" {
  alias   = "impersonation"
  project = var.PROJECT_ID
  region  = var.region
}


data "google_client_config" "default" {
  provider = google.impersonation
}

data "google_service_account_access_token" "default" {
  provider               = google.impersonation
  target_service_account = var.SERVICE_ACCOUNT_EMAIL
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "1200s"
}

provider "google" {
  alias           = "impersonated"
  project         = var.PROJECT_ID
  region          = var.region
  access_token    = data.google_service_account_access_token.default.access_token
  request_timeout = "600s"
}

# Data Lake Bucket
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data-lake-bucket" {
  provider      = google.impersonated
  name          = "${var.data_lake_bucket}_${var.PROJECT_ID}" # Concatenating DL bucket & Project name for unique naming
  location      = var.region
  project       = var.PROJECT_ID
  force_destroy = true

  # Optional, but recommended settings:
  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 // days
    }
  }
}

# DWH
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "dataset" {
  provider                   = google.impersonated
  description                = "Dataset for temperature data"
  delete_contents_on_destroy = true
  dataset_id                 = var.BQ_DATASET
  project                    = var.PROJECT_ID
  location                   = var.region
}

# VM
# Ref: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "default" {
  provider                  = google.impersonated
  description               = "Machine to run this projects code"
  name                      = "test"
  machine_type              = "e2-standard-4"
  project                   = var.PROJECT_ID
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    device_name = "dtc-de-zoomcamp"
    auto_delete = true
    initialize_params {
      size  = 30
      image = "ubuntu-2204-jammy-v20230114"
      type  = "pd-balanced"

    }
  }

  network_interface {
    network = "default"
    project = var.PROJECT_ID
    zone = var.zone

    access_config {
      //Ephemeral IP
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = var.SERVICE_ACCOUNT_EMAIL
    scopes = ["cloud-platform"]
  }

  provisioner "file" {
    source      = "../setup/setup.sh"
    destination = "./setup.sh"

    connection {
      type        = "ssh"
      user        = var.username
      host        = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
      private_key = file("${var.engine_private_key_file}")
      agent       = false
    }
  }

  provisioner "file" {
    content     = "export PROJECT_ID=\"${var.PROJECT_ID}\"\nexport KEY_ID=\"${var.KEY_ID}\"\nexport PRIVATE_KEY=\"${var.PRIVATE_KEY}\"\nexport SERVICE_ACCOUNT_EMAIL=\"${var.SERVICE_ACCOUNT_EMAIL}\"\nexport CLIENT_ID=\"${var.CLIENT_ID}\"\n"
    destination = "./.envrc"

    connection {
      type        = "ssh"
      user        = var.username
      host        = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
      private_key = file("${var.engine_private_key_file}")
      agent       = false
    }
  }
}
