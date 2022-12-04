SOURCE_DIR=$(PWD)/src
SECRETS_DIR=$(PWD)/secrets

tfvars := $(SECRETS_DIR)/terrform.tfvars
params_yaml := $(SECRETS_DIR)/params.yaml

hostname		?= $(shell yq .hostname $(params_yaml))
kurl_yaml		:= $$(yq '.spec.kubernetes.clusterName="$(hostname)"' kurl-installer.yaml)

vip_range   := $(shell yq .cluster.kuppvip_cidr $(params_yaml))

define TFVARS
hostname				 = "$(hostname)"
domain					 = "$(shell yq e .domain $(params_yaml))"
project_root		 = "$(PROJECT_DIR)"

remote_ovf_url	 = "$(shell yq .remote_ovf_url $(params_yaml))"

ssh_authorized_keys = $(shell yq --output-format json .ssh.authorized_keys $(params_yaml))

workers =  "$(shell yq .cluster.workers $(params_yaml))"

cpus			= "$(shell yq .node.cpus $(params_yaml))"
memory		= "$(shell yq .node.memory $(params_yaml))"
disk_size = "$(shell yq .node.disk_size $(params_yaml))"

vsphere_server	 = "$(shell yq .vsphere.server $(params_yaml))"
vsphere_username = "$(shell yq .vsphere.username $(params_yaml))"
vsphere_password = "$(shell sops --decrypt --extract '["vsphere"]["password"]' $(params_yaml))"

vsphere_datacenter		= "$(shell yq .vsphere.datacenter $(params_yaml))"
vsphere_cluster				= "$(shell yq .vsphere.cluster $(params_yaml))"
vsphere_host					= "$(shell yq .vsphere.host $(params_yaml))"
vsphere_resource_pool = "$(shell yq .vsphere.resource_pool $(params_yaml))"

vsphere_network				 = "$(shell yq .vsphere.network $(params_yaml))"
vsphere_datastore			 = "$(shell yq .vsphere.datastore $(params_yaml))"

vsphere_folder				 = "$(shell yq .vsphere.folder $(params_yaml))"

kurl_script = "curl $(shell curl --silent -H 'Content-Type: text/yaml' --data-raw "$(kurl_yaml)" 'https://kurl.sh/installer' && echo "") | sudo bash"
endef

.PHONY: tfvars
tfvars: $(tfvars)

export TFVARS
$(tfvars): $(params_yaml)
	@echo "$$TFVARS" > $@

.PHONY: init
init: $(tfvars)
	@(cd $(SOURCE_DIR)/terraform && terraform init)

.PHONY: create
create: init test cluster 

.PHONY: cluster
cluster: $(tfvars) init
	@(cd $(SOURCE_DIR)/terraform && terraform apply -var-file $(tfvars) --auto-approve)

.PHONY: test
test: $(tfvars)
	@(cd $(SOURCE_DIR)/terraform && terraform plan -var-file $(tfvars))

.PHONY: destroy
destroy: $(tfvars)
	@(cd $(SOURCE_DIR)/terraform && terraform destroy -var-file $(tfvars) --auto-approve)

clean:
	@rm $(tfvars)

.PHONY: encrypt
encrypt: 
	@sops --encrypt --in-place $(params_yaml)

.PHONY: decrypt
decrypt: 
	@sops --decrypt --in-place $(params_yaml)
