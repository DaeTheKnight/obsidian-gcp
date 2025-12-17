resource "google_compute_firewall" "allow-access-from-google-to-ubuntu" {
  depends_on = [google_compute_network.vpc]
  name       = "allow-access-from-google-to-ubuntu"
  network    = var.vpc

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ubuntu-server-1"]
}

#########

resource "google_compute_firewall" "allow-access-from-source-to-ubuntu" {
  depends_on = [google_compute_network.vpc]
  name       = "allow-access-from-source-to-ubuntu"
  network    = var.vpc

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22", "5984", "3389"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["ubuntu-server-1"]
}