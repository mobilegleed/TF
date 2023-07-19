data "vsphere_content_library" "library" {
  name = "Holo Library"
}

data "vsphere_content_library_item" "item" {
  name       = "Ubuntu 18.04"
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

## resource "vsphere_virtual_machine" "Tanzu-WS" {
##   name             = "Tanzu-WS"
##   resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
##   datastore_id     = data.vsphere_datastore.datastore.id
##   folder           = "Holodeck"
##   num_cpus         = 2
##   memory           = 1024
##   guest_id         = "other3xLinux64Guest"
 
##   network_interface {
##     network_id = data.vsphere_network.network.id
##   }
##   disk {
##     label = "disk0"
##     size  = 20
##     thin_provisioned = true
##   }
##   cdrom {
##     client_device = true
##   }
##   clone {
##     template_uuid = data.vsphere_content_library_item.item.id
##   }
##   vapp {
##     properties ={
##       user-data = base64encode(file("${path.module}/tanzu-ws.yaml"))
##    }
##  }
## }

resource "vsphere_virtual_machine" "OC-Apache-A" {
  name             = "OC-Apache-A"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  num_cpus         = 2
  memory           = 1024
  guest_id         = "other3xLinux64Guest"
 
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 20
    thin_provisioned = true
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.item.id
  }
  vapp {
    properties ={
      user-data = base64encode(file("${path.module}/oc-web-a.yaml"))
   }
 }
}

resource "vsphere_virtual_machine" "OC-Apache-B" {
  name             = "OC-Apache-B"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  num_cpus         = 2
  memory           = 1024
  guest_id         = "other3xLinux64Guest"
 
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 20
    thin_provisioned = true
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.item.id
  }
  vapp {
    properties ={
      user-data = base64encode(file("${path.module}/oc-web-b.yaml"))
   }
 }
}

resource "vsphere_virtual_machine" "OC-DB" {
  name             = "OC-DB"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  num_cpus         = 2
  memory           = 1024
  guest_id         = "other3xLinux64Guest"
 
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 20
    thin_provisioned = true
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.item.id
  }
  vapp {
    properties ={
      user-data = base64encode(file("${path.module}/oc-db.yaml"))
   }
 }
}
