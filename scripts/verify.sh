#!/usr/bin/env bash

set -euo pipefail

readonly NAMESPACE="${TEST_NAMESPACE:-pandora-test}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly WORKLOAD_DIR="$SCRIPT_DIR/../kubernetes/test-app"

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf 'required command not found: %s\n' "$1" >&2
		exit 1
	fi
}

require_command kubectl
require_command cilium
require_command hubble

printf '%s\n' '== Kubernetes nodes =='
kubectl get nodes

printf '%s\n' '== Cluster pods =='
kubectl get pods -A

printf '%s\n' '== Cilium =='
cilium status --wait

printf '%s\n' '== Hubble components =='
kubectl -n kube-system wait --for=condition=available deployment/hubble-relay --timeout=180s
kubectl -n kube-system wait --for=condition=available deployment/hubble-ui --timeout=180s
hubble status -P

printf '%s\n' '== Test workload =='
kubectl apply -f "$WORKLOAD_DIR/deployment.yaml" -f "$WORKLOAD_DIR/service.yaml"
kubectl -n "$NAMESPACE" rollout status deployment/http-echo --timeout=180s
kubectl -n "$NAMESPACE" wait --for=condition=ready pod \
	-l app.kubernetes.io/name=http-echo --timeout=180s
kubectl -n "$NAMESPACE" get pods,service -l app.kubernetes.io/name=http-echo

test_pod="pandora-network-test-$$"
cleanup() {
	kubectl -n "$NAMESPACE" delete pod "$test_pod" --ignore-not-found >/dev/null 2>&1 || true
}
trap cleanup EXIT

printf '%s\n' '== DNS and Service routing =='
kubectl -n "$NAMESPACE" run "$test_pod" \
	--image=busybox:1.36 \
	--labels=app.kubernetes.io/name=network-client \
	--restart=Never \
	--command -- sh -c \
	"nslookup http-echo.${NAMESPACE}.svc.cluster.local && wget -qO- http://http-echo.${NAMESPACE}.svc.cluster.local >/dev/null"
kubectl -n "$NAMESPACE" wait --for=jsonpath='{.status.phase}'=Succeeded \
	"pod/$test_pod" --timeout=180s
kubectl -n "$NAMESPACE" logs "$test_pod"

printf '%s\n' '== Cilium connectivity test =='
cilium connectivity test --wait
