data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "resource_pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "random_pet" "default_password" {
  length = 4
}

locals {
  user_data = <<-DATA
  #cloud-config
  ${data.carvel_ytt.user_data.result}
  DATA
}

resource "random_id" "control_plane" {
  byte_length = 4
  
}

resource "vsphere_virtual_machine" "control_plane" {
  name     = "${local.vm_prefix}-control-plane-${random_id.control_plane.hex}"

  datacenter_id    = data.vsphere_datacenter.datacenter.id
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool.id
  host_system_id   = data.vsphere_host.host.id
  folder           = var.vsphere_folder

  num_cpus = var.cpus
  memory   = var.memory
  guest_id = "ubuntu64Guest"

  network_interface {
    network_id     = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = var.disk_size
    unit_number      = 0

    io_share_count   = 1000

    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "instance-id" = "id-${local.vm_prefix}-control-plane-${random_id.control_plane.hex}"
      "hostname"    = local.vm_prefix
      "password"    = random_pet.default_password.id
      "user-data"   = base64encode(<<-DATA
                      #cloud-config
                      fqdn: ${local.server_name}
                      ${data.carvel_ytt.user_data.result}
                      DATA
                      )
    }
  }

  ovf_deploy { 
    remote_ovf_url = var.remote_ovf_url 
    allow_unverified_ssl_cert = true

    ip_protocol          = "IPV4"
    ip_allocation_policy = "DHCP"
    disk_provisioning    = "thin"
  }

  extra_config = {
    "isolation.tools.copy.disable"         = "FALSE"
    "isolation.tools.paste.disable"        = "FALSE"
    "isolation.tools.SetGUIOptions.enable" = "TRUE"
  }

  provisioner "remote-exec" { 
    inline = [ 
      var.kurl_script, 
      "curl -o tasks.sh https://kurl.sh/latest/tasks.sh && sudo bash tasks.sh generate-admin-user"
    ] 
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }

  provisioner "file" {
    source      = "${var.project_root}/src/bash/join_script_data_source.sh"
    destination = "/tmp/join_script_data_source.sh"
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }

  provisioner "remote-exec" { 
    inline = [ 
      "echo '# limit who can use SSH\nAllowGroups ssher' | sudo tee /etc/ssh/sshd_config.d/02-limit-to-ssher.conf"
    ] 
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }
}

data "external" "join_script" {
  program = [
    "ssh",
    "-oStrictHostKeyChecking=no",
    vsphere_virtual_machine.control_plane.default_ip_address,
    "bash /tmp/join_script_data_source.sh"
  ]
}

resource "random_id" "worker" {
  count       = var.workers
  byte_length = 4
}

resource "vsphere_virtual_machine" "worker" {
  name     = "${local.vm_prefix}-worker-${random_id.worker[count.index].hex}"
  count    = var.workers

  datacenter_id    = data.vsphere_datacenter.datacenter.id
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool.id
  host_system_id   = data.vsphere_host.host.id
  folder           = var.vsphere_folder

  num_cpus = var.cpus
  memory   = var.memory
  guest_id = "ubuntu64Guest"

  network_interface {
    network_id     = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = var.disk_size
    unit_number      = 0

    io_share_count   = 1000

    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "instance-id" = "id-${local.vm_prefix}-worker-${random_id.worker[count.index].hex}"
      "hostname"    = local.vm_prefix
      "password"    = random_pet.default_password.id
      "user-data"   = base64encode(<<-DATA
                      #cloud-config
                      fqdn: ${local.vm_prefix}-worker-${random_id.worker[count.index].hex}.${var.domain}
                      ${data.carvel_ytt.user_data.result}
                      DATA
                      )
    }
  }

  ovf_deploy { 
    remote_ovf_url = var.remote_ovf_url 
    allow_unverified_ssl_cert = true

    ip_protocol          = "IPV4"
    ip_allocation_policy = "DHCP"
    disk_provisioning    = "thin"
  }

  extra_config = {
    "isolation.tools.copy.disable"         = "FALSE"
    "isolation.tools.paste.disable"        = "FALSE"
    "isolation.tools.SetGUIOptions.enable" = "TRUE"
  }

  provisioner "remote-exec" { 
    inline = [
      data.external.join_script.result["script"]
    ] 
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }

  provisioner "remote-exec" { 
    inline = [ 
      "echo '# limit who can use SSH\nAllowGroups ssher' | sudo tee /etc/ssh/sshd_config.d/02-limit-to-ssher.conf"
    ] 
    connection {
      user = "ubuntu"
      host = self.default_ip_address
    }
  }
}

