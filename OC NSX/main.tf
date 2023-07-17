terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  host                 = var.nsx_server
  username             = var.nsx_user
  password             = var.nsx_password
  allow_unverified_ssl = true
}

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
 
data "vsphere_content_library" "library" {
  name = "Holo Library"
}

data "vsphere_content_library_item" "item" {
  name       = "Ubuntu 18.04"
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

##
data "nsxt_policy_tier0_gateway" "VLC-Tier-0" {
  display_name = "VLC-Tier-0"
}

data "nsxt_policy_edge_cluster" "EC-01" {
  display_name = "EC-01"
}

data "nsxt_policy_transport_zone" "mgmt-domain-tz-overlay01" {
  display_name = "mgmt-domain-tz-overlay01"
}

resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  description               = "Tier-1 provisioned by Terraform"
  display_name              = "Tier1-gw1"
  nsx_id                    = "predefined_id"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC-01.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.VLC-Tier-0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"

  tag {
    scope = "color"
    tag   = "blue"
  }

  route_advertisement_rule {
    name                      = "rule1"
    action                    = "DENY"
    subnets                   = ["20.0.0.0/24", "21.0.0.0/24"]
    prefix_operator           = "GE"
    route_advertisement_types = ["TIER1_CONNECTED"]
  }
}

resource "nsxt_policy_segment" "OC-Web-Segment" {
  depends_on = [ nsxt_policy_tier1_gateway.tier1_gw ]
  display_name        = "OC-Web-Segment"
  description         = "OC-Web-Segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw.path
  transport_zone_path = data.nsxt_policy_transport_zone.mgmt-domain-tz-overlay01.path

  subnet {
    cidr        = "10.1.1.1/27"
    }
}

data "nsxt_policy_segment" "OC-Web-Segment" {
  depends_on = [ nsxt_policy_segment.OC-Web-Segment ]
  display_name = "OC-Web-Segment"
}

resource "nsxt_policy_segment" "OC-DB-Segment" {
  depends_on = [ nsxt_policy_tier1_gateway.tier1_gw ]
  display_name        = "OC-DB-Segment"
  description         = "OC-DB-Segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw.path
  transport_zone_path = data.nsxt_policy_transport_zone.mgmt-domain-tz-overlay01.path

  subnet {
    cidr        = "10.1.1.33/27"
    }
}

data "nsxt_policy_segment" "OC-DB-Segment" {
  depends_on = [ nsxt_policy_segment.OC-DB-Segment ]
  display_name = "OC-DB-Segment"
}

data "vsphere_network" "db" {
  name          = "OC-DB-Segment"
  datacenter_id = data.vsphere_datacenter.dc.id

  depends_on = [nsxt_policy_segment.OC-DB-Segment]
}

data "vsphere_network" "web" {
  name          = "OC-Web-Segment"
  datacenter_id = data.vsphere_datacenter.dc.id

  depends_on = [nsxt_policy_segment.OC-Web-Segment]
}

# Wait before creating VMs.  Need to give vSphere time to detect NSX segments.
resource "time_sleep" "wait" {
  create_duration = "120s"
}
##

#resource "vsphere_virtual_machine" "Tanzu-WS" {
#  name             = "Tanzu-WS"
#  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
#  datastore_id     = data.vsphere_datastore.datastore.id
#  folder           = "Holodeck"
#  num_cpus         = 2
#  memory           = 1024
#  guest_id         = "other3xLinux64Guest"
# 
#  network_interface {
#    network_id = data.vsphere_network.network.id
#  }
#  disk {
#    label = "disk0"
#    size  = 20
#    thin_provisioned = true
#  }
#  cdrom {
#    client_device = true
#  }
#  clone {
#    template_uuid = data.vsphere_content_library_item.item.id
#  }
#  vapp {
#    properties ={
#      user-data = base64encode(file("${path.module}/tanzu-ws.yaml"))
#   }
# }
#}
#
resource "vsphere_virtual_machine" "OC-Apache-A" {
  depends_on = [nsxt_policy_segment.OC-Web-Segment]
  name             = "OC-Apache-A"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  wait_for_guest_net_timeout = 0
  num_cpus         = 2
  memory           = 1024
  guest_id         = "other3xLinux64Guest"
 
  network_interface {
    network_id = data.vsphere_network.web.id
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
  depends_on = [nsxt_policy_segment.OC-Web-Segment]
  name             = "OC-Apache-B"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  wait_for_guest_net_timeout = 0
  num_cpus         = 2
  memory           = 1024
  guest_id         = "other3xLinux64Guest"
 
  network_interface {
    network_id = data.vsphere_network.web.id
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

resource "vsphere_virtual_machine" "OC_DB" {
  depends_on = [nsxt_policy_segment.OC-DB-Segment]
  name             = "OC_DB"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  wait_for_guest_net_timeout = 0
  num_cpus         = 2
  memory           = 1024
  guest_id         = "other3xLinux64Guest"
 
  network_interface {
    network_id = data.vsphere_network.db.id
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
