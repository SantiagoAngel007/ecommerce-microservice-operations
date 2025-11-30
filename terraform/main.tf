# Create VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  description             = "VPC for ${var.project_name} - ${var.environment}"

  depends_on = [
    google_project_service.required_apis
  ]
}

# Create Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-${var.environment}-subnet"
  ip_cidr_range = var.network_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  description   = "Subnet for ${var.project_name} - ${var.environment}"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# Create Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.environment}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.network_cidr]
}

resource "google_compute_firewall" "allow_external_apis" {
  name    = "${var.project_name}-${var.environment}-allow-external-apis"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com"
  ])

  service            = each.value
  disable_on_destroy = false
}

# GKE Cluster (Autopilot o Standard según configuración)
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gcp_zone != "" ? var.gcp_zone : var.gcp_region

  # Zonas específicas para cluster regional (limita distribución de nodos)
  node_locations = length(var.gke_node_locations) > 0 ? var.gke_node_locations : null

  # GKE Autopilot o Standard
  enable_autopilot = var.gke_autopilot_enabled

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Configuración solo para modo Standard (no aplica en Autopilot)
  dynamic "node_config" {
    for_each = var.gke_autopilot_enabled ? [] : [1]
    content {
      machine_type = var.gke_machine_type
      disk_size_gb = var.gke_disk_size_gb
      disk_type    = var.gke_disk_type
      
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }

  # Initial node count (solo para Standard)
  initial_node_count = var.gke_autopilot_enabled ? null : var.gke_node_count

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Master authorized networks (restrict API access)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

# Node Pool - COMENTADO: Autopilot gestiona los nodos automáticamente
# No se necesita node pool manual en modo Autopilot
# resource "google_container_node_pool" "primary" {
#   name       = var.gke_node_pool_name
#   location   = var.gcp_region
#   cluster    = google_container_cluster.primary.name
#   node_count = var.gke_node_count
#
#   autoscaling {
#     min_node_count = var.gke_min_node_count
#     max_node_count = var.gke_max_node_count
#   }
#
#   management {
#     auto_repair  = true
#     auto_upgrade = true
#   }
#
#   node_config {
#     preemptible  = var.environment == "prod" ? false : true
#     machine_type = var.gke_machine_type
#     disk_size_gb = 30
#
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/cloud-platform"
#     ]
#
#     workload_metadata_config {
#       mode = "GKE_METADATA"
#     }
#
#     shielded_instance_config {
#       enable_secure_boot          = true
#       enable_integrity_monitoring = true
#     }
#
#     labels = {
#       environment = var.environment
#       managed_by  = "terraform"
#     }
#
#     tags = concat(var.tags, ["kubernetes-node", var.environment])
#   }
# }

# Service Account for Kubernetes workloads
resource "google_service_account" "kubernetes_workload" {
  account_id   = "${var.project_name}-${var.environment}-k8s-workload"
  display_name = "Kubernetes Workload SA for ${var.environment}"
}

# Cloud SQL Instance - COMENTADO: Quota de SSD insuficiente (100GB disponibles)
# Los microservicios usarán H2 en memoria (configurado en application-dev.yml)
# resource "google_sql_database_instance" "instance" {
#   name                = "${var.project_name}-${var.environment}-db"
#   database_version    = var.database_version
#   region              = var.gcp_region
#   deletion_protection = var.environment == "prod" ? true : false
#
#   settings {
#     tier              = var.database_tier
#     availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
#     disk_type         = "PD_SSD"
#     disk_size         = var.database_storage_gb
#     disk_autoresize   = true
#
#     # Backup
#     backup_configuration {
#       enabled                        = true
#       start_time                     = "03:00"
#       transaction_log_retention_days = 7
#       backup_retention_settings {
#         retained_backups = 30
#         retention_unit   = "COUNT"
#       }
#     }
#
#     # IP Configuration
#     ip_configuration {
#       ipv4_enabled                                  = true
#       private_network                               = google_compute_network.vpc.id
#       # enable_private_path_for_cloudsql_cloud_sql    = true  # COMENTADO: argumento inválido en provider actual
#       require_ssl                                   = var.environment == "prod" ? true : false
#     }
#
#     # Database flags (cloudsql_iam_authentication flag comentado - puede causar error 404)
#     # database_flags {
#     #   name  = "cloudsql_iam_authentication"
#     #   value = "on"
#     # }
#
#     # Insights
#     insights_config {
#       query_insights_enabled  = true
#       query_plans_per_minute  = 5
#       query_string_length     = 1024
#       record_application_tags = true
#     }
#   }
#
#   depends_on = [
#     google_project_service.required_apis,
#     google_service_networking_connection.private_vpc_connection
#   ]
# }

# Private VPC Connection for Cloud SQL - COMENTADO (no necesario sin Cloud SQL)
# resource "google_compute_global_address" "private_ip_address" {
#   name          = "${var.project_name}-${var.environment}-private-ip"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = google_compute_network.vpc.id
# }
#
# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = google_compute_network.vpc.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
# }

# Database - COMENTADO (microservicios usarán H2)
# resource "google_sql_database" "ecommerce_db" {
#   name     = var.database_name
#   instance = google_sql_database_instance.instance.name
# }
#
# # Database User
# resource "google_sql_user" "db_user" {
#   name     = var.database_user
#   instance = google_sql_database_instance.instance.name
#   password = random_password.db_password.result
# }
#
# resource "random_password" "db_password" {
#   length  = 32
#   special = true
# }

# Artifact Registry Repository
resource "google_artifact_registry_repository" "microservices" {
  location      = var.gcp_region
  repository_id = var.artifact_registry_repository_name
  description   = "Docker repository for microservices - ${var.environment}"
  format        = "DOCKER"

  depends_on = [
    google_project_service.required_apis
  ]
}

# Create a secret for database password - COMENTADO (no necesario sin Cloud SQL)
# resource "google_secret_manager_secret" "db_password" {
#   secret_id = "${var.project_name}-${var.environment}-db-password"
#
#   replication {
#     auto {}
#   }
#
#   depends_on = [
#     google_project_service.required_apis
#   ]
# }
#
# resource "google_secret_manager_secret_version" "db_password" {
#   secret      = google_secret_manager_secret.db_password.id
#   secret_data = random_password.db_password.result
# }

# IAM binding for Kubernetes workload to access Cloud SQL - COMENTADO (no necesario sin Cloud SQL)
# resource "google_project_iam_member" "workload_sql_client" {
#   project = var.gcp_project_id
#   role    = "roles/cloudsql.client"
#   member  = "serviceAccount:${google_service_account.kubernetes_workload.email}"
# }

# Local file with cluster connection info
resource "local_file" "kubeconfig_instructions" {
  filename = "${path.module}/kubeconfig-${var.environment}.sh"
  content = <<-EOT
    #!/bin/bash
    # Instrucciones para conectar kubectl al cluster GKE
    
    # 1. Autenticar con GCP
    gcloud auth login
    
    # 2. Configurar proyecto
    gcloud config set project ${var.gcp_project_id}
    
    # 3. Obtener credenciales del cluster
    gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
      --region ${var.gcp_region} \
      --project ${var.gcp_project_id}
    
    # 4. Verificar conexión
    kubectl get nodes
    kubectl get namespaces
    
    echo "¡Conectado a cluster GKE: ${google_container_cluster.primary.name}!"
  EOT
}
