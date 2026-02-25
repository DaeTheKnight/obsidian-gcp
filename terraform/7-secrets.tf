# This creates a service account for the VM
resource "google_service_account" "vm_sa" {
  account_id   = "obsidian-vm-sa"
  display_name = "Service Account for Obsidian VM"
}


# This creates the "Secret" (the container/name)
resource "google_secret_manager_secret" "obsidian_user" {
  secret_id = "obsidian-user"
  replication {
    auto {}
  }
}

# This creates the "Version" (the actual data)
resource "google_secret_manager_secret_version" "obsidian_user_v1" {
  secret      = google_secret_manager_secret.obsidian_user.id
  secret_data = var.couch_user
}


# This creates the "Secret" (the container/name)
resource "google_secret_manager_secret" "obsidian_pw" {
  secret_id = "obsidian-password"
  replication {
    auto {}
  }
}

# This creates the "Version" (the actual data)
resource "google_secret_manager_secret_version" "obsidian_pw_v1" {
  secret      = google_secret_manager_secret.obsidian_pw.id
  secret_data = var.couch_pass
}


# --- 3. PERMISSIONS (CRITICAL) ---
# This allows your VM's Service Account to actually read these secrets.
# Replace 'google_service_account.vm_sa.email' with your actual VM service account.

resource "google_secret_manager_secret_iam_member" "user_accessor" {
  secret_id = google_secret_manager_secret.obsidian_user.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "pass_accessor" {
  secret_id = google_secret_manager_secret.obsidian_pw.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm_sa.email}"
}