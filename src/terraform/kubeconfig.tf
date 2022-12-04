data "external" "kubeconfig" {
  program = [
    "ssh",
    "-oStrictHostKeyChecking=no",
    "-l",
    "ubuntu",
    vsphere_virtual_machine.control_plane.default_ip_address,
    "jq -n --rawfile kubeconfig ubuntu.conf '{ \"config\": $kubeconfig }'"
  ]
}

resource "local_sensitive_file" "kubeconfig" {
    content  = data.external.kubeconfig.result["config"]
    filename = "${local.directories.secrets}/kubeconfig"
}

