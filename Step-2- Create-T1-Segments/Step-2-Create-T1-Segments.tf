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

##data "nsxt_policy_segment" "OC-Web-Segment" {
##  depends_on = [ nsxt_policy_segment.OC-Web-Segment ]
##  display_name = "OC-Web-Segment"
##}

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

##data "nsxt_policy_segment" "OC-DB-Segment" {
##  depends_on = [ nsxt_policy_segment.OC-DB-Segment ]
##  display_name = "OC-DB-Segment"
##}

##data "vsphere_network" "db" {
##  name          = "OC-DB-Segment"
##  datacenter_id = data.vsphere_datacenter.dc.id
##
##  depends_on = [nsxt_policy_segment.OC-DB-Segment]
##}

##data "vsphere_network" "web" {
##  name          = "OC-Web-Segment"
##  datacenter_id = data.vsphere_datacenter.dc.id
##
##  depends_on = [nsxt_policy_segment.OC-Web-Segment]
##}
