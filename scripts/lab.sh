#!/usr/bin/env bash
# Collect ONLY actual IBM Cloud / Kubernetes lab command output.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/evidence"
mkdir -p "$OUT"
MY_NAMESPACE="$(printenv MY_NAMESPACE || true)"

require_environment() {
  for tool in docker kubectl ibmcloud; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing command: $tool" >&2; exit 1; }
  done
  if [[ -z "$MY_NAMESPACE" ]] || ! [[ "$MY_NAMESPACE" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
    echo "Set MY_NAMESPACE to your real IBM Cloud registry namespace (ibmcloud cr namespace-list)." >&2
    exit 1
  fi
}
render_manifest() {
  sed "s/__NAMESPACE__/$MY_NAMESPACE/g" \
    "$ROOT/$1/guestbook/deployment.yml" > "$OUT/deployment-$1.yml"
}
build_push_deploy() {
  local version="$1"
  render_manifest "$version"
  ( cd "$ROOT/$version/guestbook"; docker build -t "us.icr.io/$MY_NAMESPACE/guestbook:$version" . )
  if [[ "$version" == "v1" ]]; then
    docker push "us.icr.io/$MY_NAMESPACE/guestbook:v1"
    ibmcloud cr images | tee "$OUT/crimages"
    kubectl apply -f "$OUT/deployment-v1.yml"
  else
    docker push "us.icr.io/$MY_NAMESPACE/guestbook:v2" 2>&1 | tee "$OUT/upguestbook"
    kubectl apply -f "$OUT/deployment-v2.yml" | tee "$OUT/deployment"
  fi
  kubectl rollout status deployment/guestbook --timeout=180s
  kubectl get pods -l app=guestbook
}
start_autoscale() {
  if ! kubectl get hpa guestbook >/dev/null 2>&1; then
    kubectl autoscale deployment guestbook --cpu-percent=5 --min=1 --max=10
  fi
  kubectl get hpa guestbook | tee "$OUT/hpa"
  if ! kubectl get service guestbook >/dev/null 2>&1; then
    kubectl expose deployment guestbook --port=3000 --target-port=3000
  fi
  if ! kubectl get pod load-generator >/dev/null 2>&1; then
    kubectl run load-generator --restart=Never --image=busybox:1.36 -- \
      /bin/sh -c 'while true; do wget -q -O- http://guestbook:3000/ > /dev/null || true; done'
  fi
  echo "Check real HPA metrics with kubectl get hpa guestbook."
  echo "When replicas increase, run: bash scripts/lab.sh hpa-after"
}
capture_hpa_after() {
  kubectl get hpa guestbook | tee "$OUT/hpa2"
  local replicas
  replicas="$(kubectl get hpa guestbook -o jsonpath='{.status.currentReplicas}')"
  if [[ ! "$replicas" =~ ^[0-9]+$ ]] || (( replicas < 2 )); then
    echo "Autoscaling is not yet verified (replicas: $replicas)." >&2
    echo "Check: kubectl top pods; kubectl describe hpa guestbook" >&2
    exit 1
  fi
  echo "Actual autoscaling observed: $replicas replicas."
}
capture_rollback() {
  kubectl rollout history deployment/guestbook
  local revision
  revision="$(kubectl get deployment guestbook -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
  if [[ -z "$revision" ]]; then echo "Missing rollout revision" >&2; exit 1; fi
  kubectl rollout history deployment/guestbook --revision="$revision" | tee "$OUT/rev"
  kubectl rollout undo deployment/guestbook
  kubectl rollout status deployment/guestbook --timeout=180s
  kubectl get rs -l app=guestbook | tee "$OUT/rs"
}
if (( $# != 1 )); then
  echo "Usage: bash scripts/lab.sh {v1|autoscale|hpa-after|v2|rollback|cleanup}"
  exit 1
fi
case "$1" in
  v1|autoscale|hpa-after|v2|rollback)
    require_environment
    case "$1" in
      v1) build_push_deploy v1 ;;
      autoscale) start_autoscale ;;
      hpa-after) capture_hpa_after ;;
      v2) build_push_deploy v2 ;;
      rollback) capture_rollback ;;
    esac
    ;;
  cleanup) kubectl delete pod load-generator --ignore-not-found=true ;;
  *) echo "Unknown command: $1" >&2; exit 1 ;;
esac
