SHELL := /bin/bash

REMOTE_HOST ?= mac-mini
REMOTE_REPO ?= ~/Projects/pandora
KUBECONFIG ?= $(HOME)/.kube/mac-mini-k3s.yaml

TOOLS = ./scripts/with-tools.sh
KUBECONFIG_ENV = KUBECONFIG="$(KUBECONFIG)"

.PHONY: bootstrap kubeconfig migrate-state tf-init plan apply verify teardown

bootstrap:
	ssh -t "$(REMOTE_HOST)" 'cd $(REMOTE_REPO) && ./scripts/with-tools.sh ./host/start-colima.sh'

kubeconfig:
	$(TOOLS) env $(KUBECONFIG_ENV) REMOTE_HOST="$(REMOTE_HOST)" REMOTE_REPO="$(REMOTE_REPO)" ./scripts/kubeconfig.sh

migrate-state:
	$(TOOLS) env REMOTE_HOST="$(REMOTE_HOST)" ./scripts/migrate-state.sh

tf-init:
	$(TOOLS) env $(KUBECONFIG_ENV) terraform -chdir=terraform init

plan:
	$(TOOLS) env $(KUBECONFIG_ENV) terraform -chdir=terraform plan

apply:
	$(TOOLS) env $(KUBECONFIG_ENV) terraform -chdir=terraform apply

verify:
	$(TOOLS) env $(KUBECONFIG_ENV) ./scripts/verify.sh

teardown:
	$(TOOLS) env $(KUBECONFIG_ENV) REMOTE_HOST="$(REMOTE_HOST)" REMOTE_REPO="$(REMOTE_REPO)" ./scripts/teardown.sh
