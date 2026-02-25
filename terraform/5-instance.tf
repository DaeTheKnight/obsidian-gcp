# data "google_compute_zones" "obsidian" {
#   region = var.region
# }

resource "google_compute_instance" "notes-vm" {
  depends_on   = [google_compute_network.vpc]
  name         = "notes-vm-2"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["ubuntu-server-1"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 30
    }
  }

    service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"] # This allows the VM to call Google APIs
  }

  metadata_startup_script = file("startup-script.sh")

  network_interface {
    network    = var.vpc
    subnetwork = var.subnet
    access_config {
    }
  }
}
