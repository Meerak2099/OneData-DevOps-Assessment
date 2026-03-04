#!/bin/bash

# Complete Kubernetes Setup and Deployment Script for Bash
# This script installs Minikube (if needed), starts the cluster, and deploys the app

set -e

echo "======================================"
echo "Kubernetes Setup & Deployment Script"
echo "======================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Detect OS
OS_TYPE=$(uname -s)
print_status "Detected OS: $OS_TYPE"

# Check if Docker is running
print_status "Checking Docker..."
if docker info > /dev/null 2>&1; then
    print_success "Docker is running"
else
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Check if kubectl is installed
print_status "Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl not found. Installing..."
    
    if [ "$OS_TYPE" == "Darwin" ]; then
        # macOS
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    elif [ "$OS_TYPE" == "Linux" ]; then
        # Linux
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    elif [[ "$OS_TYPE" == *"MINGW"* ]] || [[ "$OS_TYPE" == *"MSYS"* ]] || [[ "$OS_TYPE" == *"CYGWIN"* ]]; then
        # Windows Git Bash
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/windows/amd64/kubectl.exe"
        mkdir -p /usr/local/bin
        mv kubectl.exe /usr/local/bin/
    fi
    print_success "kubectl installed"
else
    print_success "kubectl found"
    kubectl version --client --short
fi

# Check if Minikube is installed, if not install it
print_status "Checking Minikube..."
if ! command -v minikube &> /dev/null; then
    print_warning "Minikube not found. Installing..."
    
    if [ "$OS_TYPE" == "Darwin" ]; then
        # macOS
        curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-amd64
        chmod +x minikube-darwin-amd64
        sudo mv minikube-darwin-amd64 /usr/local/bin/minikube
    elif [ "$OS_TYPE" == "Linux" ]; then
        # Linux
        curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
        chmod +x minikube-linux-amd64
        sudo mv minikube-linux-amd64 /usr/local/bin/minikube
    elif [[ "$OS_TYPE" == *"MINGW"* ]] || [[ "$OS_TYPE" == *"MSYS"* ]] || [[ "$OS_TYPE" == *"CYGWIN"* ]]; then
        # Windows Git Bash
        curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe
        mkdir -p /usr/local/bin
        mv minikube-windows-amd64.exe /usr/local/bin/minikube.exe
    fi
    print_success "Minikube installed"
else
    print_success "Minikube found"
    minikube version
fi

# Start Minikube
print_status "Starting Minikube cluster..."
if minikube status | grep -q "Running"; then
    print_success "Minikube is already running"
else
    print_warning "Starting Minikube (this may take 1-2 minutes)..."
    minikube start --driver=docker --cpus=2 --memory=4096 || true
fi

# Verify cluster is running
print_status "Verifying cluster..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Failed to connect to cluster. Retrying..."
    sleep 5
    minikube start --driver=docker
fi

print_success "Cluster is running"
kubectl cluster-info

# Get cluster info
print_status "Cluster Information:"
kubectl get nodes

# Navigate to project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
print_status "Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Update deployment manifest
print_status "Updating deployment manifest..."
DOCKER_USERNAME="meerak1099"
IMAGE_TAG="main"
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")

sed -e "s|docker.io/USERNAME/simple-python-app:COMMIT_SHA|docker.io/${DOCKER_USERNAME}/simple-python-app:${IMAGE_TAG}|g" k8s/deployment.yaml > k8s/deployment-updated.yaml

print_success "Deployment manifest updated"

# Display the updated manifest
print_status "Updated Deployment Manifest:"
cat k8s/deployment-updated.yaml
echo ""

# Deploy to Kubernetes
print_status "Deploying application to Kubernetes..."
kubectl apply -f k8s/deployment-updated.yaml
kubectl apply -f k8s/service.yaml

print_success "Manifests applied"

# Wait for deployment
print_status "Waiting for deployment to be ready (timeout: 3 minutes)..."
if kubectl rollout status deployment/simple-python-app --timeout=3m; then
    print_success "Deployment is ready!"
else
    print_warning "Deployment did not reach ready state within timeout"
    print_status "Checking pod status..."
    kubectl get pods -l app=simple-python-app
fi

echo ""
echo "======================================"
echo "DELIVERABLES - Take Screenshots"
echo "======================================"
echo ""

# Capture Pods
print_status "Pods Status:"
echo "$ kubectl get pods -l app=simple-python-app"
kubectl get pods -l app=simple-python-app -o wide
echo ""

# Capture Services
print_status "Services:"
echo "$ kubectl get svc simple-python-app"
kubectl get svc simple-python-app -o wide
echo ""

# Capture Deployments
print_status "Deployments:"
echo "$ kubectl get deployments simple-python-app"
kubectl get deployments simple-python-app -o wide
echo ""

# Capture detailed info
print_status "Detailed Pod Information:"
FIRST_POD=$(kubectl get pods -l app=simple-python-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$FIRST_POD" ]; then
    echo "$ kubectl describe pod $FIRST_POD"
    kubectl describe pod "$FIRST_POD"
    echo ""
    
    echo "$ kubectl logs $FIRST_POD"
    kubectl logs "$FIRST_POD" --tail=20
    echo ""
fi

# Service access information
print_status "Service Access Information:"
SERVICE_IP=$(kubectl get svc simple-python-app -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
print_success "Cluster IP: $SERVICE_IP"

# For Minikube, get the service URL
if command -v minikube &> /dev/null; then
    print_status "Getting Minikube service URL..."
    SERVICE_URL=$(minikube service simple-python-app --url 2>/dev/null || echo "N/A")
    print_success "Service URL: $SERVICE_URL"
fi

echo ""
echo "======================================"
echo "Available Commands"
echo "======================================"
echo ""
echo "View logs:"
echo "  kubectl logs -l app=simple-python-app"
echo ""
echo "Port forward (local testing):"
echo "  kubectl port-forward svc/simple-python-app 8000:80"
echo ""
echo "Test API endpoints:"
echo "  curl http://localhost:8000/api/health"
echo "  curl http://localhost:8000/api/endpoint"
echo ""
echo "Get into a pod:"
echo "  kubectl exec -it <pod-name> -- /bin/bash"
echo ""
echo "Delete deployment:"
echo "  kubectl delete -f k8s/deployment-updated.yaml k8s/service.yaml"
echo ""
echo "Stop Minikube:"
echo "  minikube stop"
echo ""

print_success "Deployment Complete!"
print_status "Next steps:"
echo "1. Take screenshots of pods, services, and deployments above"
echo "2. Take screenshot of GitHub Actions workflow (Actions tab)"
echo "3. Configure GitHub Environment for manual approval gate"
echo "4. Submit deliverables as listed in README.md"
