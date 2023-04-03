variable "username" {
  description = "username of your gcloud account"
  type        = string
  sensitive   = true
}

variable "engine_private_key_file" {
  description = "Private ssh key file for communicating with VMs in gcloud"
  type        = string
  sensitive   = true
}

variable "data_lake_bucket" {
  description = "Name of the datalake bucket to store the data in"
  type        = string
}

variable "PROJECT_ID" {
  description = "Your GCP Project ID"
  type        = string
  sensitive   = true
}

variable "KEY_ID" {
  description = "The key id of your service account private key"
  type        = string
  sensitive   = true
}

variable "PRIVATE_KEY" {
  description = "The private key id of your service account"
  type        = string
  sensitive   = true
}

variable "SERVICE_ACCOUNT_EMAIL" {
  description = "The service account email"
  type        = string
  sensitive   = true
}

variable "CLIENT_ID" {
  description = "The client id of your service account"
  type        = string
  sensitive   = true
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

