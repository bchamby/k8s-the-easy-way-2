provider "google" {
  credentials = "${file("secrets/account.json")}"
  project     = "k8s-the-easy-way-2"
  region      = "us-central1"
}

resource "google_compute_network" "k8s-the-easy-way" {
  name = "k8s-the-easy-way"
}

resource "google_compute_subnetwork" "k8s" {
  name          = "k8s"
  network       = "${google_compute_network.k8s-the-easy-way.name}"
  ip_cidr_range = "10.240.0.0/24"
}

resource "google_compute_firewall" "allow-internal" {
  name          = "allow-internal"
  network       = "${google_compute_network.k8s-the-easy-way.name}"
  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow-external" {
  name          = "allow-external"
  network       = "${google_compute_network.k8s-the-easy-way.name}"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol    = "tcp"
    ports       = ["22", "6443"]
  }
  allow {
    protocol    = "icmp"
  }
}

resource "google_compute_firewall" "allow-health-checks" {
  name          = "allow-health-checks"
  network       = "${google_compute_network.k8s-the-easy-way.name}"
  source_ranges = ["209.85.204.0/22", "209.85.152.0/22", "35.191.0.0/16"]
  allow {
    protocol    = "tcp"
    ports       = ["8080"]
  }
}

resource "google_compute_address" "k8s-the-easy-way" {
  name = "k8s-the-easy-way"
}

resource "google_compute_instance" "controller" {
  count          = 3
  name           = "controller-${count.index}"
  machine_type   = "n1-standard-1"
  zone           = "us-central1-a"
  tags           = ["controller", "controller-${count.index}"]
  boot_disk {
    initialize_params {
      image      = "ubuntu-os-cloud/ubuntu-1604-lts"
      size       = 200
    }
  }
  can_ip_forward = true
  network_interface {
    subnetwork   = "${google_compute_subnetwork.k8s.name}"
    address      = "10.240.0.${count.index+10}"
    access_config {
    }
  }
  metadata {
    sshKeys      = "${var.gce_ssh_user}:${file(var.gce_ssh_public_key_file)}"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_instance" "worker" {
  count        = 3
  name         = "worker-${count.index}"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  tags         = ["worker", "worker-${count.index}"]
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
      size  = 200
    }
  }
  can_ip_forward = true
  network_interface {
    subnetwork = "${google_compute_subnetwork.k8s.name}"
    address    = "10.240.0.${count.index+20}"
    access_config {
    }
  }
  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_public_key_file)}"
  }

  metadata {
    pod-cidr = "10.240.0.${count.index}/24"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_http_health_check" "apiserver" {
  name         = "apiserver"
  request_path = "/healthz"
  port         = "8080"
}

resource "google_compute_target_pool" "apiserver" {
  name          = "apiserver"
  instances     = [
    "us-central1-a/controller-0",
    "us-central1-a/controller-1",
    "us-central1-a/controller-2",
  ]
  health_checks = [
    "${google_compute_http_health_check.apiserver.name}"
  ]
}

resource "google_compute_forwarding_rule" "apiserver" {
  "name"     = "apiserver"
  target     = "${google_compute_target_pool.apiserver.self_link}"
  port_range = "6443"
  ip_address = "${google_compute_address.k8s-the-easy-way.address}"
}

resource "google_compute_route" "k8s-route" {
  count       = 3
  name        = "k8s-route-worker-${count.index}"
  network     = "${google_compute_network.k8s-the-easy-way.name}"
  dest_range  = "10.200.${count.index}.0/24"
  next_hop_ip = "10.240.0.2${count.index}"
  priority    = 1000
}
