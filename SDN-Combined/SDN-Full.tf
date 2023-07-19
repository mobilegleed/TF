
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
 
resource "vsphere_content_library_item" "ubuntu_20_04" {
  name        = "Ubuntu 20.04"
  description = "Ubuntu template"
  library_id  = vsphere_content_library.library.id
  file_url = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.ova"
}
 
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

##data "vsphere_content_library" "library" {
##  name = "Holo Library"
##  depends_on = [ vsphere_content_library.library ]
##}

##data "vsphere_content_library_item" "item" {
##  name       = "Ubuntu 18.04"
##  type       = "ovf"
##  library_id = data.vsphere_content_library.library.id
##}

resource "vsphere_virtual_machine" "OC-Apache-A" {
  depends_on       = [vsphere_content_library.library]
  name             = "OC-Apache-A"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  wait_for_guest_net_timeout = 0
  num_cpus         = 2
  memory           = 1024
  guest_id         = "ubuntu64Guest"
 
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
    template_uuid = vsphere_content_library_item.ubuntu_18_04.id
  }
  vapp {
    properties ={
      user-data = base64encode(file("${path.module}/oc-web-a.yaml"))
   }
 }
 lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode
    ]
  }
}

resource "vsphere_virtual_machine" "OC-Apache-B" {
  depends_on       = [vsphere_content_library.library]
  name             = "OC-Apache-B"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  wait_for_guest_net_timeout = 0
  num_cpus         = 2
  memory           = 1024
  guest_id         = "ubuntu64Guest"
 
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
    template_uuid = vsphere_content_library_item.ubuntu_18_04.id
  }
  vapp {
    properties ={
      user-data = base64encode(file("${path.module}/oc-web-b.yaml"))
   }
 }
 lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode
    ]
  }
}

resource "vsphere_virtual_machine" "OC-DB" {
  depends_on       = [vsphere_content_library.library]
  name             = "OC-DB"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "Holodeck"
  wait_for_guest_net_timeout = 0
  num_cpus         = 2
  memory           = 1024
  guest_id         = "ubuntu64Guest"
 
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
    template_uuid = vsphere_content_library_item.ubuntu_18_04.id
  }
  vapp {
    properties ={
      user-data = base64encode(file("${path.module}/oc-db.yaml"))
   }
 }
 lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode
    ]
  }
}
##data "vsphere_virtual_machine" "OC-Apache-A" {
##  name          = "OC-Apache-A"
##  datacenter_id = data.vsphere_datacenter.dc.id
##}

##data "vsphere_virtual_machine" "OC-Apache-B" {
##  name          = "OC-Apache-B"
##  datacenter_id = data.vsphere_datacenter.dc.id
##}

##data "vsphere_virtual_machine" "OC-DB" {
##  name          = "OC-DB"
##  datacenter_id = data.vsphere_datacenter.dc.id
##}

resource "nsxt_policy_vm_tags" "OC-Apache-A-tags" {
  instance_id = vsphere_virtual_machine.OC-Apache-A.id
  depends_on = [ vsphere_virtual_machine.OC-Apache-A ]

  tag {
    scope = "app"
    tag   = "OC-Web-Tag"
  }
}

resource "nsxt_policy_vm_tags" "OC-Apache-B-tags" {
  instance_id = vsphere_virtual_machine.OC-Apache-B.id

  tag {
    scope = "app"
    tag   = "OC-Web-Tag"
  }
}

resource "nsxt_policy_vm_tags" "OC-B-tags" {
  instance_id = vsphere_virtual_machine.OC-DB.id

 tag {
    scope = "app"
    tag   = "OC-DB-Tag"
  }
}

resource "nsxt_policy_group" "OC-Web-Group" {
  display_name = "OC-Web-Group"
  description  = "OC Web Group"

  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = "OC-Web-Tag"
    }
  }
}


resource "nsxt_policy_group" "OC-DB-Group" {
  display_name = "OC-DB-Group"
  description  = "OC DB Group"

  criteria {
    condition {
      key	  = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = "OC-DB-Tag"
    }
  }
}

data "nsxt_policy_service" "ssh" {
  display_name = "SSH"
}

data "nsxt_policy_service" "http" {
  display_name = "HTTP"
}

data "nsxt_policy_service" "rdp" {
  display_name = "RDP"
}

data "nsxt_policy_service" "ntp" {
  display_name = "NTP"
}

data "nsxt_policy_service" "icmp" {
  display_name = "ICMP ALL"
}

data "nsxt_policy_service" "mysql" {
  display_name = "MySQL"
}

data "nsxt_policy_service" "dns-tcp" {
  display_name = "DNS-TCP"
}

data "nsxt_policy_service" "dns-udp" {
  display_name = "DNS-UDP"
}

resource "nsxt_policy_security_policy" "policy1" {
  display_name = "policy1"
  description  = "Terraform provisioned Security Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = false
##  scope        = [nsxt_policy_group.OC-Web-Group.path]

  rule {
    display_name       = "stop lateral for web"
    source_groups      = [nsxt_policy_group.OC-Web-Group.path]
    destination_groups = [nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path]
    action             = "DROP"
    logged             = true
  }

  rule {
    display_name       = "stop lateral for db"
    source_groups      = [nsxt_policy_group.OC-DB-Group.path]
    destination_groups = [nsxt_policy_group.OC-DB-Group.path]
    scope              = [nsxt_policy_group.OC-DB-Group.path]
    action             = "DROP"
    logged             = true
  }

  rule {
    display_name       = "HTTP allow inbound"
    source_groups      = ["10.0.0.0/24"]
    destination_groups = [nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.http.path]
    logged             = true
  }

  rule {
    display_name       = "Web to DB"
    source_groups      = [nsxt_policy_group.OC-Web-Group.path]
    destination_groups = [nsxt_policy_group.OC-DB-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.mysql.path]
    logged             = true
  }

  rule {
    display_name       = "ICMP allow inbound"
    source_groups      = ["10.0.0.0/24"]
    destination_groups = [nsxt_policy_group.OC-DB-Group.path, nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.icmp.path]
    logged             = true
  }

  rule {
    display_name       = "SSH allow inbound"
    source_groups      = ["10.0.0.0/24"]
    destination_groups = [nsxt_policy_group.OC-DB-Group.path, nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.ssh.path]
    logged             = true
  }

  rule {
    display_name       = "RDP allow inbound"
    source_groups      = ["10.0.0.0/24"]
    destination_groups = [nsxt_policy_group.OC-DB-Group.path, nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-DB-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.rdp.path]
    logged             = true
  }

  rule {
    display_name       = "NTP allow inbound"
    source_groups      = ["10.0.0.0/24"]
    destination_groups = [nsxt_policy_group.OC-DB-Group.path, nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.ntp.path]
    logged             = true
  }

  rule {
    display_name       = "DNS allow outbound"
    source_groups      = [nsxt_policy_group.OC-DB-Group.path, nsxt_policy_group.OC-Web-Group.path]
    scope              = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.dns-tcp.path, data.nsxt_policy_service.dns-udp.path]
    logged             = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "nsxt_policy_gateway_policy" "OpenCart-Policy" {
  display_name    = "OpenCart-Policy"
  description     = "OpenCart GW Policy"
  category        = "LocalGatewayRules"
  locked          = false
  sequence_number = 3
  stateful        = true
  tcp_strict      = false

  tag {
    scope = "color"
    tag   = "orange"
  }

  rule {
    display_name       = "HTTP allow inbound"
    destination_groups = [nsxt_policy_group.OC-Web-Group.path]
    disabled           = true
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.http.path]
    logged             = true
    scope              = [nsxt_policy_tier1_gateway.tier1_gw.path]
  }

  rule {
    display_name       = "ICMP allow inbound"
    destination_groups = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    disabled           = true
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.icmp.path]
    logged             = true
    scope              = [nsxt_policy_tier1_gateway.tier1_gw.path]
  }

  rule {
    display_name       = "SSH allow inbound"
    destination_groups = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    disabled           = true
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.ssh.path]
    logged             = true
    scope              = [nsxt_policy_tier1_gateway.tier1_gw.path]
  }

  rule {
    display_name       = "RDP allow inbound"
    destination_groups = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    disabled           = true
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.rdp.path]
    logged             = true
    scope              = [nsxt_policy_tier1_gateway.tier1_gw.path]
  }

  rule {
    display_name       = "NTP allow outbound"
    source_groups       = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    disabled           = true
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.ntp.path]
    logged             = true
    scope              = [nsxt_policy_tier1_gateway.tier1_gw.path]
  }

  rule {
    display_name       = "DNS allow outbound"
    source_groups       = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
    disabled           = true
    action             = "ALLOW"
    services           = [data.nsxt_policy_service.dns-tcp.path, data.nsxt_policy_service.dns-udp.path]
    logged             = true
    scope              = [nsxt_policy_tier1_gateway.tier1_gw.path]
  }
  lifecycle {
    create_before_destroy = true
  }
}
