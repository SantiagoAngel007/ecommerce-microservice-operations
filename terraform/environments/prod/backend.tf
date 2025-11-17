terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-ssd"
    prefix      = "prod"
    credentials = "../../credentials/gcp-key.json"
  }
}
