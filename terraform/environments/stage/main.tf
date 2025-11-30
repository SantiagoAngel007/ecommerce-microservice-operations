# Staging environment - Reference root terraform module
module "gke_stage" {
  source = "../.."

  # Load variables from terraform.tfvars
  gcp_project_id       = var.gcp_project_id
  gcp_region           = var.gcp_region
  gcp_credentials_path = var.gcp_credentials_path
  environment          = var.environment
  gke_cluster_name     = var.gke_cluster_name
  kubernetes_version   = var.kubernetes_version
  
  # GKE cluster mode and node configuration
  gke_autopilot_enabled = var.gke_autopilot_enabled
  gke_node_count        = var.gke_node_count
  gke_machine_type      = var.gke_machine_type
  gke_disk_size_gb      = var.gke_disk_size_gb
  gke_disk_type         = var.gke_disk_type
  
  # Database configuration
  database_version    = var.database_version
  database_tier       = var.database_tier
  database_storage_gb = var.database_storage_gb
  database_name       = var.database_name
  database_user       = var.database_user
  
  # Artifact Registry
  artifact_registry_repository_name = var.artifact_registry_repository_name
}

# Variables que necesitamos declarar
variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_credentials_path" {
  type    = string
  default = "../../credentials/gcp-key.json"
}

variable "environment" {
  type = string
}

variable "gke_cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "gke_autopilot_enabled" {
  type    = bool
  default = false
}

variable "gke_node_count" {
  type    = number
  default = 2
}

variable "gke_machine_type" {
  type    = string
  default = "e2-standard-8"
}

variable "gke_min_node_count" {
  type    = number
  default = 2
}

variable "gke_max_node_count" {
  type    = number
  default = 4
}

variable "gke_disk_size_gb" {
  type    = number
  default = 50
}

variable "gke_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "database_version" {
  type = string
}

variable "database_tier" {
  type = string
}

variable "database_storage_gb" {
  type    = number
  default = 10
}

variable "database_name" {
  type    = string
  default = "ecommerce_stage_db"
}

variable "database_user" {
  type    = string
  default = "stage_user"
}

variable "artifact_registry_repository_name" {
  type    = string
  default = "ecommerce-repo"
}

# Outputs
output "cluster_name" {
  value = module.gke_stage.gke_cluster_name
}

output "cluster_endpoint" {
  value     = module.gke_stage.gke_cluster_endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.gke_stage.gke_cluster_ca_certificate
  sensitive = true
}
