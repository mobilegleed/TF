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
 
## data "vsphere_content_library_item" "library_item_ubuntu_18_04" {
##  name       = "ubuntu 18.04"
##  library_id = vsphere_content_library.library.id
##  type = "OVA"
## }

resource "vsphere_content_library_item" "ubuntu_20_04" {
  name        = "Ubuntu 20.04"
  description = "Ubuntu template"
  library_id  = vsphere_content_library.library.id
  file_url = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.ova"
}
 
## data "vsphere_content_library_item" "library_item_ubuntu_20_04" {
##   name       = "ubuntu 20.04"
##   library_id = vsphere_content_library.library.id
##   type = "OVA"
## }

## # Wait before creating VMs.  Need to give vSphere time to detect NSX segments.
## resource "time_sleep" "wait" {
##   create_duration = "120s"
##}
