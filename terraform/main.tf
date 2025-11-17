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

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.gcp_region

  initial_node_count = var.gke_node_count
  network            = google_compute_network.vpc.name
  subnetwork         = google_compute_subnetwork.subnet.name

  # We can't create this cluster with "remove_default_node_pool" and
  # specify "node_pool" at the same time, so we'll create the primary node pool.
  remove_default_node_pool = true

  # Configure cluster options
  enable_shielded_nodes = true

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled = true
  }

  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = true
  }

  # Cluster autoscaling
  cluster_autoscaling {
    enabled = false
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Required for Cloud SQL connections
  database_encryption {
    state = "ENCRYPTED"
  }

  # Master authorized networks (restrict API access)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

# Node Pool
resource "google_container_node_pool" "primary" {
  name       = var.gke_node_pool_name
  location   = var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_node_count

  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = var.environment == "prod" ? false : true
    machine_type = var.gke_machine_type
    disk_size_gb = 100

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }

    tags = concat(var.tags, ["kubernetes-node", var.environment])
  }
}

# Service Account for Kubernetes workloads
resource "google_service_account" "kubernetes_workload" {
  account_id   = "${var.project_name}-${var.environment}-k8s-workload"
  display_name = "Kubernetes Workload SA for ${var.environment}"
}

# Cloud SQL Instance
resource "google_sql_database_instance" "instance" {
  name                = "${var.project_name}-${var.environment}-db"
  database_version    = var.database_version
  region              = var.gcp_region
  deletion_protection = var.environment == "prod" ? true : false

  settings {
    tier              = var.database_tier
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.database_storage_gb
    disk_autoresize   = true

    # Backup
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    # IP Configuration
    ip_configuration {
      ipv4_enabled                                  = true
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_cloudsql_cloud_sql    = true
      require_ssl                                   = var.environment == "prod" ? true : false
    }

    # Database flags
    database_flags {
      name  = "cloudsql_iam_authentication"
      value = "on"
    }

    # Insights
    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Private VPC Connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Database
resource "google_sql_database" "ecommerce_db" {
  name     = var.database_name
  instance = google_sql_database_instance.instance.name
}

# Database User
resource "google_sql_user" "db_user" {
  name     = var.database_user
  instance = google_sql_database_instance.instance.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

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

# Create a secret for database password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_name}-${var.environment}-db-password"

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# IAM binding for Kubernetes workload to access Cloud SQL
resource "google_project_iam_member" "workload_sql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.kubernetes_workload.email}"
}

# Local file with cluster connection info
resource "local_file" "kubeconfig_instructions" {
  filename = "${path.module}/kubeconfig-${var.environment}.sh"
  content = templatefile("${path.module}/kubeconfig-template.sh", {
    cluster_name = google_container_cluster.primary.name
    gcp_region   = var.gcp_region
    gcp_project  = var.gcp_project_id
  })
}
