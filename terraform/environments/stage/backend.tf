terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-479317"
    prefix      = "stage"
    credentials = "../../credentials/gcp-key.json"
  }
}
