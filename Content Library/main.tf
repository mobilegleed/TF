provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.data_center
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.workload_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_network" "network" {
  name          = "sddc-vds01-mgmt"
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
resource "vsphere_content_library" "library" {
  name            = "Holo Library"
  storage_backing = [data.vsphere_datastore.datastore.id]
  description     = "A new source of content"
}

resource "vsphere_content_library_item" "ubuntu_18_04" {
  name        = "Ubuntu 18.04"
  description = "Ubuntu template"
  library_id  = vsphere_content_library.library.id
  file_url = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.ova"
}
 
data "vsphere_content_library_item" "library_item_ubuntu_18_04" {
  name       = "ubuntu 18.04"
  library_id = vsphere_content_library.library.id
  type = "OVA"
}

resource "vsphere_content_library_item" "ubuntu_20_04" {
  name        = "Ubuntu 20.04"
  description = "Ubuntu template"
  library_id  = vsphere_content_library.library.id
  file_url = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.ova"
}
 
data "vsphere_content_library_item" "library_item_ubuntu_20_04" {
  name       = "ubuntu 20.04"
  library_id = vsphere_content_library.library.id
  type = "OVA"
}
 
