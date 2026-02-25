terraform {
  backend "gcs" {
    bucket      = "state-ubuntu-2"
    prefix      = "terraform/state-2"
    #credentials = "key.json"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
