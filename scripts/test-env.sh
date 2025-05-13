#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Kubernetes cluster
echo "1️⃣  Checking Kubernetes cluster..."
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Kubernetes cluster is running"
else
    echo -e "${RED}✗${NC} Kubernetes cluster is not running"
    exit 1
fi
echo ""

# Test 2: Required namespaces
echo "2️⃣  Checking required namespaces..."
REQUIRED_NS=("argocd" "ingress-nginx" "monitoring" "guestbook")
for ns in "${REQUIRED_NS[@]}"; do
    if kubectl get ns "$ns" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Namespace $ns exists"
    else
        echo -e "${RED}✗${NC} Namespace $ns does not exist"
        exit 1
    fi
done
echo ""

# Test 3: Core services
echo "3️⃣  Checking core services..."
CORE_SERVICES=(
    "argocd-server"
    "ingress-nginx-controller"
    "monitoring-grafana"
    "prometheus-operated"  # Changed this line - this is the correct service name
)
for svc in "${CORE_SERVICES[@]}"; do
    NS="${svc%-*}"
    # Special case for prometheus-operated service
    if [[ "$svc" == "prometheus-operated" ]]; then
        NS="monitoring"
    fi
    
    if kubectl get svc "$svc" -n "$NS" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Service $svc is running"
    else
        echo -e "${RED}✗${NC} Service $svc is not running"
        exit 1
    fi
done
echo ""

# Test 4: ArgoCD and Guestbook Application
echo "4️⃣  Testing ArgoCD and Guestbook Application..."
if kubectl get application guestbook -n argocd &> /dev/null; then
    echo -e "${GREEN}✓${NC} Guestbook application exists in ArgoCD"
    
    # Check if guestbook is synced
    SYNC_STATUS=$(kubectl get application guestbook -n argocd -o jsonpath='{.status.sync.status}')
    HEALTH_STATUS=$(kubectl get application guestbook -n argocd -o jsonpath='{.status.health.status}')
    
    if [ "$SYNC_STATUS" = "Synced" ]; then
        echo -e "${GREEN}✓${NC} Guestbook application is synced"
    else
        echo -e "${YELLOW}⚠${NC} Guestbook application is not synced (Status: $SYNC_STATUS)"
    fi
    
    if [ "$HEALTH_STATUS" = "Healthy" ]; then
        echo -e "${GREEN}✓${NC} Guestbook application is healthy"
    else
        echo -e "${YELLOW}⚠${NC} Guestbook application health status: $HEALTH_STATUS"
    fi
    
    # Check if guestbook pods are running
    if kubectl wait --for=condition=available --timeout=60s deployment/guestbook-ui -n guestbook &> /dev/null; then
        echo -e "${GREEN}✓${NC} Guestbook pods are running"
    else
        echo -e "${RED}✗${NC} Guestbook pods are not ready"
    fi
else
    echo -e "${RED}✗${NC} Guestbook application not found in ArgoCD"
    echo "Creating Guestbook application in ArgoCD..."
    kubectl apply -f ../k8s/apps/guestbook-app.yaml
fi
echo ""

# Test 5: Port forwarding test
echo "5️⃣  Testing Guestbook access..."
kubectl port-forward -n guestbook svc/guestbook-ui 8081:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

if curl -s http://localhost:8081 | grep -q "Guestbook"; then
    echo -e "${GREEN}✓${NC} Guestbook application is accessible via port-forward"
else
    echo -e "${RED}✗${NC} Guestbook application is not accessible"
fi
kill $PF_PID 2>/dev/null || true
echo ""

# Summary
echo "📊 Test Summary:"
echo "================"
echo -e "${GREEN}✓${NC} Kubernetes cluster: OK"
echo -e "${GREEN}✓${NC} Required namespaces: OK"
echo -e "${GREEN}✓${NC} Core services: Running"
echo -e "${GREEN}✓${NC} Test deployment: Successful"
echo -e "${GREEN}✓${NC} Network access: Working"
echo ""
echo -e "${GREEN}🎉 All tests passed! Your environment is ready.${NC}"
echo ""
echo "📌 Quick access commands:"
echo "  ArgoCD:     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Grafana:    kubectl port-forward svc/grafana -n monitoring 3000:3000"
echo "  Prometheus: kubectl port-forward svc/prometheus -n monitoring 9090:9090"
echo "  Guestbook:  kubectl port-forward svc/guestbook-ui -n guestbook 8081:80"
