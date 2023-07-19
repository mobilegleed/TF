
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

##  rule {
##    display_name       = "block_icmp"
##    destination_groups = [nsxt_policy_group.OC-DB-Group.path, nsxt_policy_group.OC-Web-Group.path]
##    action             = "DROP"
##    services           = [data.nsxt_policy_service.icmp.path]
##    logged             = true
##  }

##  rule {
##    display_name     = "allow_ssh"
##    source_groups    = [nsxt_policy_group.OC-Web-Group.path]
##    sources_excluded = true
##    scope            = [nsxt_policy_group.aquarium.path]
##    action           = "ALLOW"
##    services         = [data.nsxt_policy_service.ssh.path]
##    logged           = true
##    disabled         = true
##    notes            = "Disabled by starfish for debugging"
##  }

  lifecycle {
    create_before_destroy = true
  }
}

##resource "nsxt_policy_gateway_policy" "test" {
##  display_name    = "tf-gw-policy"
##  description     = "Terraform provisioned Gateway Policy"
##  category        = "LocalGatewayRules"
##  locked          = false
##  sequence_number = 3
##  stateful        = true
##  tcp_strict      = false
##
##  tag {
##    scope = "color"
##    tag   = "orange"
##  }
##
##  rule {
##    display_name       = "rule1"
##    destination_groups = [nsxt_policy_group.OC-Web-Group.path, nsxt_policy_group.OC-DB-Group.path]
##    disabled           = true
##    action             = "DROP"
##    logged             = true
##    scope              = [data.nsxt_policy_tier1_gateway.Tier1-gw.path]
##  }
##
##  lifecycle {
##    create_before_destroy = true
##  }
##}
