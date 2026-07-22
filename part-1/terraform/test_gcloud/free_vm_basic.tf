
provider "google" {
  project = ""
  region  = "us-central1"
  zone    = "us-central1-a"
}


resource "google_compute_instance" "free-vm" {
  name         = "free-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}


output "public_ip" {
  value = google_compute_instance.free-vm.network_interface[0].access_config[0].nat_ip
}
