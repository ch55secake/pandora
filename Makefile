SHELL := /bin/bash

REMOTE_HOST ?= mac-mini
REMOTE_REPO ?= ~/pandora
KUBECONFIG ?= $(HOME)/.kube/mac-mini-k3s.yaml
NIX ?= nix

NIX_DEVELOP = $(NIX) develop --command
KUBECONFIG_ENV = KUBECONFIG="$(KUBECONFIG)"

.PHONY: bootstrap tunnel kubeconfig tf-init plan apply verify

bootstrap:
	ssh "$(REMOTE_HOST)" 'cd $(REMOTE_REPO) && nix develop --command ./host/start-colima.sh'

tunnel:
	$(NIX_DEVELOP) ./scripts/tunnel.sh

kubeconfig:
	$(NIX_DEVELOP) env $(KUBECONFIG_ENV) ./scripts/kubeconfig.sh

tf-init:
	$(NIX_DEVELOP) env $(KUBECONFIG_ENV) terraform -chdir=terraform init

plan:
	$(NIX_DEVELOP) env $(KUBECONFIG_ENV) terraform -chdir=terraform plan

apply:
	$(NIX_DEVELOP) env $(KUBECONFIG_ENV) terraform -chdir=terraform apply

verify:
	$(NIX_DEVELOP) env $(KUBECONFIG_ENV) ./scripts/verify.sh
