#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Kubernetes Development Environment Setup...${NC}"

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. Aborting." >&2; exit 1; }

# Create KIND cluster using Terraform
echo -e "${GREEN}Creating KIND cluster...${NC}"
cd "$(dirname "$0")/../terraform"
terraform init
terraform apply -auto-approve

# Wait for cluster to be ready
echo -e "${GREEN}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install ArgoCD
echo -e "${GREEN}Installing ArgoCD...${NC}"
kubectl create namespace argocd || true
kubectl apply -f ../k8s/argocd/install.yaml
kubectl apply -f ../k8s/argocd/manifests/install.yaml

# Install NGINX Ingress
echo -e "${GREEN}Installing NGINX Ingress Controller...${NC}"
kubectl apply -f ../k8s/ingress/nginx-ingress.yaml

# Install Monitoring Stack
echo -e "${GREEN}Installing Monitoring Stack...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring || true
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values ../k8s/monitoring/values.yaml

# Setup port-forwarding in the background
echo -e "${GREEN}Setting up port-forwarding...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
# kubectl port-forward svc/argocd-server -n argocd 8080:80 &
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:80 &

# Wait for Grafana pod to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 &

# Get access credentials
echo -e "${GREEN}Getting access credentials...${NC}"
echo -e "${BLUE}ArgoCD Initial Password:${NC}"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo -e "${BLUE}Grafana Initial Password:${NC}"
echo "admin" # Set in values.yaml

echo -e "${GREEN}Setup complete! You can now access:${NC}"
echo -e "ArgoCD UI: http://localhost:8080 (user: admin)"
echo -e "Grafana: http://localhost:3000 (user: admin, password: admin)"
echo -e "\nPort-forwarding is running in the background. To stop it, run: pkill -f 'kubectl port-forward'"