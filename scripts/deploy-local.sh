#!/bin/bash
# Local Kubernetes Deployment Script
# This script deploys the application to a local Minikube or kind cluster

set -e

echo "======================================"
echo "Local Kubernetes Deployment Script"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if cluster is available
echo -e "${YELLOW}Checking Kubernetes cluster...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kubernetes cluster not found!${NC}"
    echo ""
    echo "To set up a local cluster:"
    echo ""
    echo "Option 1: Minikube"
    echo "  1. Install Minikube: https://minikube.sigs.k8s.io/docs/start/"
    echo "  2. Start cluster: minikube start"
    echo "  3. Run this script again"
    echo ""
    echo "Option 2: kind"
    echo "  1. Install kind: https://kind.sigs.k8s.io/docs/user/quick-start/"
    echo "  2. Create cluster: kind create cluster"
    echo "  3. Run this script again"
    exit 1
fi

echo -e "${GREEN}✓ Kubernetes cluster found!${NC}"
kubectl cluster-info

# Get Git commit SHA for image tag
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
DOCKER_USERNAME="meerak1099"
IMAGE_TAG="main"

echo ""
echo -e "${YELLOW}Deployment Configuration:${NC}"
echo "  Image: docker.io/${DOCKER_USERNAME}/simple-python-app:${IMAGE_TAG}"
echo "  Commit SHA: ${COMMIT_SHA}"
echo ""

# Update deployment manifest with correct image
echo -e "${YELLOW}Updating deployment manifest...${NC}"
sed -e "s|docker.io/USERNAME/simple-python-app:COMMIT_SHA|docker.io/${DOCKER_USERNAME}/simple-python-app:${IMAGE_TAG}|g" k8s/deployment.yaml > k8s/deployment-updated.yaml

echo -e "${YELLOW}Deployment manifest:${NC}"
cat k8s/deployment-updated.yaml
echo ""

# Apply manifests
echo -e "${YELLOW}Deploying to Kubernetes...${NC}"
kubectl apply -f k8s/deployment-updated.yaml
kubectl apply -f k8s/service.yaml

echo ""
echo -e "${YELLOW}Waiting for deployment to be ready (timeout 2m)...${NC}"
if kubectl rollout status deployment/simple-python-app --timeout=2m; then
    echo -e "${GREEN}✓ Deployment successful!${NC}"
else
    echo -e "${RED}⚠ Deployment did not reach ready state within timeout${NC}"
fi

echo ""
echo -e "${YELLOW}Current Deployment Status:${NC}"
echo ""
echo "Pods:"
kubectl get pods -l app=simple-python-app
echo ""
echo "Services:"
kubectl get svc simple-python-app
echo ""
echo "Deployments:"
kubectl get deployments simple-python-app
echo ""

# Get service access info
echo -e "${YELLOW}Service Access Info:${NC}"
SERVICE_IP=$(kubectl get svc simple-python-app -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "pending")
echo "  Cluster IP: ${SERVICE_IP}"

# For Minikube, get the service URL
if command -v minikube &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Minikube Service URL:${NC}"
    minikube service simple-python-app --url || echo "  Run: minikube service simple-python-app"
fi

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:        kubectl logs -l app=simple-python-app"
echo "  Port forward:     kubectl port-forward svc/simple-python-app 8000:80"
echo "  Get pod details:  kubectl describe pod <pod-name>"
echo "  Delete app:       kubectl delete -f k8s/deployment-updated.yaml k8s/service.yaml"
