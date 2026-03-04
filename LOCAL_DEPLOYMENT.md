# Local Kubernetes Deployment Guide

This guide will help you deploy the application to a local Kubernetes cluster (Minikube or kind) and capture the deliverables.

## Prerequisites

- Docker installed and running
- git installed
- A terminal/PowerShell

## Step 1: Install Kubernetes Cluster

### Option A: Minikube (Recommended)

```bash
# Windows - Download and install from:
# https://minikube.sigs.k8s.io/docs/start/

# Or using Chocolatey:
choco install minikube

# Start Minikube
minikube start

# Verify
kubectl cluster-info
minikube version
```

### Option B: kind (Kubernetes in Docker)

```bash
# Install kind from:
# https://kind.sigs.k8s.io/docs/user/quick-start/

# Or using Chocolatey:
choco install kind

# Create cluster
kind create cluster

# Verify
kubectl cluster-info
kubectl get nodes
```

## Step 2: Deploy Application

Run the deployment script from the project root:

```bash
cd c:/Users/meera/OneDrive/Pictures/Documents/PROJECT/1/simple-python-app

# Make the script executable (on Unix/Bash)
chmod +x scripts/deploy-local.sh

# Run deployment
bash scripts/deploy-local.sh
```

Or manually deploy:

```bash
# Update the deployment manifest with correct image
sed -i 's|docker.io/USERNAME/simple-python-app:COMMIT_SHA|docker.io/meerak1099/simple-python-app:main|g' k8s/deployment.yaml

# Apply manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check status
kubectl rollout status deployment/simple-python-app --timeout=2m
```

## Step 3: Verify Deployment

### Get Deliverable Screenshots

```bash
# 1. Get Pods Status (DELIVERABLE)
kubectl get pods -l app=simple-python-app

# 2. Get Services (DELIVERABLE)
kubectl get svc simple-python-app

# 3. Get Deployments (DELIVERABLE)
kubectl get deployments simple-python-app

# 4. Get detailed pod info
kubectl describe pod <pod-name>

# 5. View logs
kubectl logs <pod-name>
```

## Step 4: Access the Application

### Port Forwarding

```bash
# Forward local port 8000 to service port 80
kubectl port-forward svc/simple-python-app 8000:80

# In another terminal, test endpoints:
curl http://localhost:8000/api/health
curl http://localhost:8000/api/endpoint
```

### Minikube Service

```bash
# Get service URL (Minikube only)
minikube service simple-python-app --url

# This returns the actual URL you can use in browser or curl
```

## Step 5: Cleanup

```bash
# Delete the deployment
kubectl delete -f k8s/deployment.yaml k8s/service.yaml

# Or delete the entire cluster
minikube delete
# OR
kind delete cluster
```

## Troubleshooting

### Pods not starting
```bash
# Check pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>

# Check if image exists locally (for testing)
docker images | grep simple-python-app
```

### Service not accessible
```bash
# Check service endpoints
kubectl get endpoints simple-python-app

# Check if service is LoadBalancer or ClusterIP
kubectl get svc simple-python-app -o yaml

# For Minikube, ensure port-forward is running
kubectl port-forward svc/simple-python-app 8000:80
```

### Image pull issues
```bash
# Check image pull events
kubectl describe pod <pod-name> | grep -i "pull"

# Ensure image exists on Docker Hub
docker pull docker.io/meerak1099/simple-python-app:main

# Tag and test locally
docker run -p 8000:8000 docker.io/meerak1099/simple-python-app:main
```

## GitHub Actions vs Local Deployment

| Aspect | GitHub Actions | Local Deployment |
|--------|---|---|
| Checkout | ✓ | Manual |
| Lint | ✓ | Can run locally |
| Unit Tests | ✓ | ✓ |
| Docker Build | ✓ | Manual |
| Docker Push | ✓ | Manual |
| Kubernetes Deploy | ✗ (no cluster) | ✓ |
| Integration Tests | ⚠ (no service) | ✓ |

## Deliverables Checklist

- [ ] Screenshot: `kubectl get pods -l app=simple-python-app`
- [ ] Screenshot: `kubectl get svc simple-python-app`
- [ ] Screenshot: `kubectl get deployments simple-python-app`
- [ ] Screenshot: GitHub Actions successful workflow run
- [ ] Screenshot: Manual approval gate in GitHub (environment staging)
- [ ] Repository link: https://github.com/Meerak2099/OneData-DevOps-Assessment

## Example Output

```bash
$ kubectl get pods -l app=simple-python-app
NAME                                    READY   STATUS    RESTARTS   AGE
simple-python-app-7d4c8b5c6-abc12     1/1     Running   0          2m
simple-python-app-7d4c8b5c6-def45     1/1     Running   0          2m

$ kubectl get svc simple-python-app
NAME                  TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
simple-python-app     LoadBalancer   10.96.100.200    localhost     80:32000/TCP   2m

$ kubectl get deployments simple-python-app
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
simple-python-app     2/2     2            2           2m
```
