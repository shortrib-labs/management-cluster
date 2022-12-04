output "password" {
  value     = random_pet.default_password.id
  sensitive = true
}

output "node_ip" {
  value     = vsphere_virtual_machine.control_plane.default_ip_address
}

output "join_script" {
  value     = data.external.join_script.result["script"]
  sensitive = true
}

output "kubeconfig" {
  value     = data.external.kubeconfig.result["config"]
  sensitive = true
}
