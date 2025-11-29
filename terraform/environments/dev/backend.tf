terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-479317"
    prefix      = "dev"
    credentials = "../../credentials/gcp-key.json"
  }
}
