variable "gcp_project" {}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-c"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_service_account" "quantum_infra_sa" {
  account_id   = "quantum-infra-service-account"
  display_name = "Infrastructure Service Account"
}

resource "google_service_account" "quantum_svc_sa" {
  account_id   = "quantum-svc-service-account"
  display_name = "Service Deployment Service Account"
}

resource "google_project_iam_custom_role" "quantum_infra_admin_role" {
  role_id     = "quantum_infra_admin_role"
  title       = "quantum_infra_admin_role"
  description = "Infrastructure Administrator Custom Role"
  permissions = [
    "compute.disks.create",
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.instanceGroupManagers.get",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.instances.setTags",
    "compute.machineTypes.get",
    "compute.networks.create",
    "compute.networks.delete",
    "compute.networks.get",
    "compute.networks.updatePolicy",
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.get",
    "compute.subnetworks.setPrivateIpGoogleAccess",
    "compute.subnetworks.update",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.zones.get",
    "container.clusters.create",
    "container.clusters.delete",
    "container.clusters.get",
    "container.clusters.update",
    "container.operations.get",
  ]
}

resource "google_project_iam_custom_role" "quantum_svc_admin_role" {
  role_id     = "quantum_svc_admin_role"
  title       = "quantum_svc_admin_role"
  description = "Service Deployment Custom Role"
  permissions = [
    "container.apiServices.get",
    "container.apiServices.list",
    "container.clusters.get",
    "container.clusters.getCredentials",
  ]
}

resource "google_project_iam_binding" "quantum_infra_binding" {
  role = "projects/${var.gcp_project}/roles/${google_project_iam_custom_role.quantum_infra_admin_role.role_id}"

  members = [
    "serviceAccount:${google_service_account.quantum_infra_sa.email}",
  ]
}

resource "google_project_iam_binding" "quantum_svc_binding" {
  role = "projects/${var.gcp_project}/roles/${google_project_iam_custom_role.quantum_svc_admin_role.role_id}"

  members = [
    "serviceAccount:${google_service_account.quantum_svc_sa.email}",
  ]
}

resource "google_project_iam_binding" "quantum_infra_sa_adm_binding" {
  role = "roles/iam.serviceAccountAdmin"

  members = [
    "serviceAccount:${google_service_account.quantum_infra_sa.email}",
  ]
}

resource "google_project_iam_binding" "quantum_infra_sa_usr_binding" {
  role = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.quantum_infra_sa.email}",
  ]
}


resource "google_container_cluster" "quantum" {
  provider   = google-beta
  name       = "quantum-cluster"
  location   = var.gcp_region

  remove_default_node_pool = true
  initial_node_count = 1
  master_auth {
    username = ""
    password = ""
  }


  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      service = "quantum"
    }

    tags = ["http-server", "https-server"]
  }

}

resource "google_container_node_pool" "quantum_nodes" {
  name       = "quantum-node-pool"
  cluster    = google_container_cluster.quantum.name
  location   = var.gcp_region
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

