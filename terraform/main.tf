provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "autopilot" {
  name     = "cdp-autopilot"
  location = var.region
  initial_node_count = 1
  enable_autopilot = true
  release_channel {
    channel = "REGULAR"
  }
}

resource "google_storage_bucket" "gcs_bucket" {
  name     = var.gcs_bucket
  location = var.region
  uniform_bucket_level_access = true
}