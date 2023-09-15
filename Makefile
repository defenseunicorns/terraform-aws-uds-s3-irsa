.PHONY: help
help:
	@grep -E '^[/a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1:\3/p' \
	| column -t -s ":" | sort

.PHONY: clean
clean: ## Remove the temp 'build' directory
	rm -rf build

.PHONY: deploy/generic
deploy/generic: copy-files deploy/customizations deploy/uds-dubbd deploy/uds-idam deploy/uds-sso deploy/secrets ## Deploy the stack on a generic K8s cluster

.PHONY: deploy/aws
deploy/aws: pre-deploy/aws copy-files deploy/customizations deploy/uds-dubbd-aws deploy/uds-idam-aws deploy/uds-sso deploy/secrets ## Deploy the stack on AWS EKS

.PHONY: deploy/aws-west-region
deploy/aws-west-region: pre-deploy/aws copy-files deploy/customizations deploy/uds-dubbd-aws post-dubbd-deploy deploy/cert-manager deploy/uds-idam-aws deploy/uds-sso deploy/secrets ## Deploy the stack on AWS EKS

.PHONY: deploy/kind
deploy/kind: copy-files deploy/customizations deploy/uds-dubbd-kind deploy/uds-idam deploy/uds-sso deploy/secrets ## Deploy the stack on a KinD cluster

.PHONY: deploy/uds-dubbd
deploy/uds-dubbd: ## Deploy the UDS DUBBD Package
	cd ./build && zarf package deploy oci://ghcr.io/defenseunicorns/packages/dubbd:0.7.0-amd64 --oci-concurrency=15 --confirm

.PHONY: deploy/uds-dubbd-aws
deploy/uds-dubbd-aws: ## Deploy the UDS DUBBD AWS Package
	cd ./build && zarf package deploy oci://ghcr.io/defenseunicorns/packages/dubbd-aws:0.7.0-amd64 --oci-concurrency=15 --confirm

.PHONY: deploy/uds-dubbd-kind
deploy/uds-dubbd-kind: ## Deploy the UDS DUBBD KinD Package
	cd ./build && zarf package deploy oci://ghcr.io/corang/dubbd-kind:v0.7.0-amd64 --oci-concurrency=15 --confirm

.PHONY: deploy/uds-idam
deploy/uds-idam: ## Deploy the UDS IDAM (Keycloak) Package
	cd ./build && zarf package deploy oci://ghcr.io/defenseunicorns/uds-capability/uds-idam:0.1.9-amd64 --oci-concurrency=15 --confirm

.PHONY: deploy/uds-idam-aws
deploy/uds-idam-aws: ## Deploy the UDS IDAM (Keycloak) Package for AWS
	cd ./build && zarf package deploy oci://ghcr.io/defenseunicorns/uds-capability/uds-idam-aws:0.1.9-amd64 --oci-concurrency=15 --confirm

.PHONY: deploy/cert-manager
deploy/cert-manager: ## Deploy the Cert-manager Package (RDT&E west region only)
	cd ./build && zarf package deploy oci://docker-nswccd.devops.nswccd.navy.mil/project-blue/defense-unicorns/cert-manager/cert-manager:v1.12.3-amd64 --oci-concurrency=15 --confirm

.PHONY: uninstall/uds-idam
uninstall/uds-idam: ## Uninstall the UDS IDAM Package
	cd ./build && zarf package remove uds-idam --confirm || true

.PHONY: pre-deploy/aws
pre-deploy/aws: ## Pre-Deploy Script
	scripts/pre-dubbd-deploy.sh

.PHONY: build
build: ## Create the temp 'build' directory
	mkdir -p build

.PHONY: copy-files
copy-files: | build ## Stage files before deployment
	cp assets/files/* build
	cp staging/* build
