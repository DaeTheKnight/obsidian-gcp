# data "google_compute_zones" "obsidian" {
#   region = var.region
# }

resource "google_compute_instance" "notes-vm" {
  depends_on   = [google_compute_network.vpc]
  name         = "notes-vm-1"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["ubuntu-server-1"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
    }
  }

  metadata_startup_script = file("startup-script.sh")

  network_interface {
    network    = var.vpc
    subnetwork = google_compute_subnetwork.obsidian-net.id
    access_config {
    }
  }
}
