data "vsphere_virtual_machine" "OC-Apache-A" {
  name          = "OC-Apache-A"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "OC-Apache-B" {
  name          = "OC-Apache-B"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "OC-DB" {
  name          = "OC-DB"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "nsxt_policy_vm_tags" "OC-Apache-A-tags" {
  instance_id = data.vsphere_virtual_machine.OC-Apache-A.id

  tag {
    scope = "app"
    tag   = "OC-Web-Tag"
  }
}

resource "nsxt_policy_vm_tags" "OC-Apache-B-tags" {
  instance_id = data.vsphere_virtual_machine.OC-Apache-B.id

  tag {
    scope = "app"
    tag   = "OC-Web-Tag"
  }
}

resource "nsxt_policy_vm_tags" "OC-B-tags" {
  instance_id = data.vsphere_virtual_machine.OC-DB.id

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
