terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-ssd"
    prefix      = "stage"
    credentials = "../../credentials/gcp-key.json"
  }
}
