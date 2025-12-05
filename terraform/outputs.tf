output "gke_name" { value = google_container_cluster.autopilot.name }
output "gcs_bucket" { value = google_storage_bucket.gcs_bucket.name }