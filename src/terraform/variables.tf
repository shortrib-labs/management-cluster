variable "project_root" {
  type = string
}

variable "hostname" {
  type = string
}

variable "domain" {
  type = string
}

variable "workers" {
  type = string
}

variable "remote_ovf_url" {
  type = string
}

variable "ssh_authorized_keys" {
  type = list
}

variable "worker_count" {
  type = string
  default = 0
}

variable "cpus" {
  type    = number
  default = 4
}

variable "memory" {
  type    = number
  default = 8192
}

variable "disk_size" {
  type    = number
  default = 52
}

variable "vsphere_server" {
  type = string
}

variable "vsphere_username" {
  type = string
}

variable "vsphere_password" {
  type = string
}

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_cluster" {
  type = string
}

variable "vsphere_host" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "vsphere_network" {
  type = string
}

variable "vsphere_resource_pool" {
  type = string
}

variable "vsphere_folder" {
  type = string
}

variable "kurl_script" {
  type = string
}

locals {
  vm_prefix      = "${var.hostname}"
  server_name    = "${var.hostname}.${var.domain}"
  vsphere_folder = "${var.vsphere_datacenter}/vm/${var.vsphere_folder}"
  directories = {
    work = "${var.project_root}/work"
    secrets = "${var.project_root}/secrets"
  }
}
