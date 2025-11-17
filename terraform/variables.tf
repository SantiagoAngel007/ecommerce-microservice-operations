variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "southamerica-east1"
}

variable "gcp_credentials_path" {
  description = "Path to GCP service account key file"
  type        = string
  default     = "./credentials/gcp-key.json"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'stage', or 'prod'."
  }
}

variable "project_name" {
  description = "Project name to use in resource names"
  type        = string
  default     = "ecommerce"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "microservices"
}

# Network variables
variable "network_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for GKE cluster"
  type        = string
  default     = "1.27"
}

# GKE Cluster variables
variable "gke_cluster_name" {
  description = "GKE Cluster name"
  type        = string
}

variable "gke_node_pool_name" {
  description = "GKE Node Pool name"
  type        = string
  default     = "primary-pool"
}

variable "gke_node_count" {
  description = "Initial number of nodes in GKE cluster"
  type        = number
  default     = 3
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_min_node_count" {
  description = "Minimum number of nodes in GKE cluster"
  type        = number
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum number of nodes in GKE cluster"
  type        = number
  default     = 5
}

# Cloud SQL variables
variable "database_version" {
  description = "Database version (POSTGRES_13, MYSQL_8_0, etc.)"
  type        = string
}

variable "database_tier" {
  description = "Database tier/machine type"
  type        = string
}

variable "database_storage_gb" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Default database name"
  type        = string
  default     = "ecommerce_db"
}

variable "database_user" {
  description = "Default database user"
  type        = string
  default     = "dbuser"
}

# Artifact Registry variables
variable "artifact_registry_repository_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "microservices"
}

# Tags
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    "managed_by" = "terraform"
    "project"    = "ecommerce"
  }
}

variable "tags" {
  description = "Tags for resources"
  type        = list(string)
  default     = ["terraform"]
}
