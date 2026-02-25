resource "google_compute_subnetwork" "obsidian-net-2" {
  name                     = var.subnet
  ip_cidr_range            = var.range
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}
