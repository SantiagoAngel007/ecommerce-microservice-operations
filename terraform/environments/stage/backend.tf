terraform {
  backend "gcs" {
    bucket      = "ecommerce-terraform-state-479317"
    prefix      = "stage"
    # Credenciales tomadas del ambiente (gcloud auth)
    # No especificar aquí para evitar problemas de path en Jenkins
  }
}
