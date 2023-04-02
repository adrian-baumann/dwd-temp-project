variable "username" {
  description = "username of your gcloud account"
  type        = string
}

variable "terraform_service_account" {
  description = "email of your service account"
  type        = string
}

variable "engine_private_key_file" {
  description = "value"
  type        = string
}

variable "data_lake_bucket" {
  description = "value"
  type        = string
}

variable "project" {
  description = "Your GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region for GCP resources. Choose as per your location: https://cloud.google.com/about/locations"
  default     = "europe-west6"
  type        = string
}

variable "zone" {
  description = "Region for GCP resources. Choose as per your location: https://cloud.google.com/about/locations"
  default     = "europe-west6-a"
  type        = string
}

variable "storage_class" {
  description = "Storage class type for your bucket. Check official docs for more info."
  default     = "STANDARD"
}

variable "BQ_DATASET" {
  description = "BigQuery Dataset that raw data (from GCS) will be written to"
  type        = string
  default     = "temperatures"
}

