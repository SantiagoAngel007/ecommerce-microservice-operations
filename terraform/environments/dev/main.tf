# Development environment - Reference root terraform files
module "infrastructure" {
  source = "../.."

  # Pass variables from terraform.tfvars
  gcp_project_id       = var.gcp_project_id
  gcp_region          = var.gcp_region
  gcp_zone            = var.gcp_zone
  gcp_credentials_path = var.gcp_credentials_path
  environment         = var.environment
  
  # GKE cluster configuration
  gke_cluster_name      = var.gke_cluster_name
  gke_autopilot_enabled = var.gke_autopilot_enabled
  gke_node_count        = var.gke_node_count
  gke_machine_type      = var.gke_machine_type
  gke_disk_size_gb      = var.gke_disk_size_gb
  gke_disk_type         = var.gke_disk_type
  gke_min_node_count    = var.gke_min_node_count
  gke_max_node_count    = var.gke_max_node_count
  
  kubernetes_version  = var.kubernetes_version
  
  database_version    = var.database_version
  database_tier       = var.database_tier
  database_storage_gb = var.database_storage_gb
}

# Declare all variables used
variable "gcp_project_id" { type = string }
variable "gcp_region" { type = string }
variable "gcp_zone" { 
  type = string
  default = ""
}
variable "gcp_credentials_path" { 
  type = string 
  default = "../../credentials/gcp-key.json" 
}
variable "environment" { type = string }
variable "gke_cluster_name" { type = string }
variable "gke_autopilot_enabled" { 
  type = bool
  default = false
}
variable "gke_node_count" { type = number }
variable "gke_machine_type" { type = string }
variable "gke_disk_size_gb" { type = number }
variable "gke_disk_type" { type = string }
variable "gke_min_node_count" { type = number }
variable "gke_max_node_count" { type = number }
variable "kubernetes_version" { type = string }
variable "database_version" { type = string }
variable "database_tier" { type = string }
variable "database_storage_gb" { type = number }
