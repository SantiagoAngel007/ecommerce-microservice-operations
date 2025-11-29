# VPC outputs
output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

# GKE Cluster outputs
output "gke_cluster_name" {
  description = "GKE Cluster name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE Cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "kubernetes_cluster_host" {
  description = "GKE cluster host"
  value       = "https://${google_container_cluster.primary.endpoint}"
  sensitive   = true
}

output "kubernetes_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

# Cloud SQL outputs - COMENTADO (no desplegamos Cloud SQL por quota de SSD)
# output "database_instance_name" {
#   description = "Cloud SQL instance name"
#   value       = google_sql_database_instance.instance.name
# }
#
# output "database_instance_connection_name" {
#   description = "Cloud SQL instance connection name"
#   value       = google_sql_database_instance.instance.connection_name
# }
#
# output "database_private_ip" {
#   description = "Cloud SQL instance private IP"
#   value       = google_sql_database_instance.instance.private_ip_address
# }
#
# output "database_public_ip" {
#   description = "Cloud SQL instance public IP"
#   value       = google_sql_database_instance.instance.public_ip_address
# }

# Artifact Registry outputs
output "artifact_registry_repository_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.microservices.repository_id}"
}

output "artifact_registry_repository_name" {
  description = "Artifact Registry repository name"
  value       = google_artifact_registry_repository.microservices.name
}

# Kubernetes config
output "kubernetes_config" {
  description = "Kubernetes configuration for kubectl"
  value = format(
    "gcloud container clusters get-credentials %s --region %s --project %s",
    google_container_cluster.primary.name,
    var.gcp_region,
    var.gcp_project_id
  )
}
