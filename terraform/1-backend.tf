terraform {
  backend "gcs" {
    bucket      = "state-obsidian-1"
    prefix      = "terraform/state-1"
    #credentials = "key.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
