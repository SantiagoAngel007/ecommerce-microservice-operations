terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-ssd"
    prefix      = "dev"
    credentials = "../../credentials/gcp-key.json"
  }
}
