namespaces       := $(shell ls -1 base)
bootstrap_files  := $(shell find base -name "*sync.yaml")

key_fp  := FAC1CF820538F4A07C8F4657DAD5DC6A21303194

.PHONY: all
all: bootstrap 

.PHONY: bootstrap
bootstrap: $(namespaces) $(bootstrap_files)

.PHONY: $(namespaces)
$(namespaces):
	@kubectl create namespace $@ --dry-run=client -o yaml --save-config | kubectl apply -f -
	@gpg --export-secret-keys --armor $(key_fp) \
			| kubectl create secret generic sops-gpg \
					--namespace=$@ \
					--from-file=sops.asc=/dev/stdin \
					--dry-run=client \
					--output=yaml \
					--save-config \
			| kubectl apply -f -

.PHONY: $(bootstrap_files)
$(bootstrap_files):
	@kubectl apply -f $@

