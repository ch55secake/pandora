SHELL := /bin/bash

REMOTE_HOST ?= mac-mini
REMOTE_REPO ?= ~/Projects/pandora
KUBECONFIG ?= $(HOME)/.kube/mac-mini-k3s.yaml

TOOLS = ./scripts/with-tools.sh
KUBECONFIG_ENV = KUBECONFIG="$(KUBECONFIG)"

.PHONY: bootstrap tunnel kubeconfig tf-init plan apply verify

bootstrap:
	ssh "$(REMOTE_HOST)" 'cd $(REMOTE_REPO) && ./scripts/with-tools.sh ./host/start-colima.sh'

tunnel:
	$(TOOLS) env REMOTE_HOST="$(REMOTE_HOST)" ./scripts/tunnel.sh

kubeconfig:
	$(TOOLS) env $(KUBECONFIG_ENV) REMOTE_HOST="$(REMOTE_HOST)" REMOTE_REPO="$(REMOTE_REPO)" ./scripts/kubeconfig.sh

tf-init:
	$(TOOLS) env $(KUBECONFIG_ENV) terraform -chdir=terraform init

plan:
	$(TOOLS) env $(KUBECONFIG_ENV) terraform -chdir=terraform plan

apply:
	$(TOOLS) env $(KUBECONFIG_ENV) terraform -chdir=terraform apply

verify:
	$(TOOLS) env $(KUBECONFIG_ENV) ./scripts/verify.sh
