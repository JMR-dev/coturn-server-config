provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_compute_address" "turn_static_ip" {
  name         = "stoat-turn-ip"
  network_tier = "PREMIUM"
  region       = var.gcp_region
}

resource "google_compute_instance" "turn_outpost" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  tags = ["webrtc-outpost", "caddy-web"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2404-lts-amd64"
      size  = 20
    }
  }

  metadata = var.admin_ssh_public_key == "" ? {} : {
    ssh-keys = "ubuntu:${var.admin_ssh_public_key}"
  }

  network_interface {
    network = var.network_name

    access_config {
      nat_ip       = google_compute_address.turn_static_ip.address
      network_tier = "PREMIUM"
    }
  }
}

resource "google_compute_firewall" "webrtc_rules" {
  name    = "allow-webrtc-and-web"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3478", "5349"]
  }

  allow {
    protocol = "udp"
    ports    = ["3478", "49152-65535"]
  }

  target_tags = ["webrtc-outpost", "caddy-web"]
}

output "relay_ip" {
  description = "Public static IP for the relay."
  value       = google_compute_address.turn_static_ip.address
}
