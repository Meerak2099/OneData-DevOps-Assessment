#!/usr/bin/env powershell
# Comprehensive CI/CD & Kubernetes Setup Script
# This script checks prerequisites, installs if needed, and deploys the application

param(
    [switch]$SkipDependencyCheck = $false,
    [switch]$DeployOnly = $false
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error-Custom { Write-Host $args -ForegroundColor Red }
function Write-Warning-Custom { Write-Host $args -ForegroundColor Yellow }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

$ErrorActionPreference = "Stop"

Write-Info "========================================"
Write-Info "CI/CD & Kubernetes Setup Script"
Write-Info "========================================"
Write-Info ""

# Step 1: Check Prerequisites
Write-Info "[1/5] Checking Prerequisites..."
$prerequisites = @{
    "git" = "git --version"
    "docker" = "docker --version"
    "kubectl" = "kubectl version --client"
}

$missingTools = @()

foreach ($tool in $prerequisites.Keys) {
    try {
        $result = Invoke-Expression $prerequisites[$tool] 2>&1
        Write-Success "✓ $tool is installed"
    }
    catch {
        Write-Error-Custom "✗ $tool is NOT installed"
        $missingTools += $tool
    }
}

if ($missingTools -and -not $SkipDependencyCheck) {
    Write-Error-Custom ""
    Write-Error-Custom "Missing prerequisites: $($missingTools -join ', ')"
    Write-Error-Custom ""
    Write-Error-Custom "Please install:"
    if ($missingTools -contains "docker") {
        Write-Error-Custom "  - Docker Desktop: https://www.docker.com/products/docker-desktop"
    }
    if ($missingTools -contains "git") {
        Write-Error-Custom "  - Git: https://git-scm.com/download/win"
    }
    if ($missingTools -contains "kubectl") {
        Write-Error-Custom "  - kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/"
    }
    exit 1
}

# Step 2: Check/Install Minikube
Write-Info ""
Write-Info "[2/5] Checking Minikube..."
try {
    $minikubeVersion = minikube version 2>&1
    Write-Success "✓ Minikube is installed: $minikubeVersion"
}
catch {
    Write-Warning-Custom "✗ Minikube not found. Installing..."
    
    # Check if Chocolatey is available
    try {
        choco --version | Out-Null
        Write-Info "  Installing Minikube via Chocolatey..."
        choco install minikube -y --force
        Write-Success "✓ Minikube installed successfully"
    }
    catch {
        Write-Error-Custom "Chocolatey not found. Please install Minikube manually:"
        Write-Error-Custom "  https://minikube.sigs.k8s.io/docs/start/"
        Write-Error-Custom "Or install Chocolatey first: https://chocolatey.org/install"
        exit 1
    }
}

# Step 3: Start Minikube Cluster
Write-Info ""
Write-Info "[3/5] Starting Kubernetes Cluster..."
try {
    $clusterInfo = kubectl cluster-info 2>&1
    Write-Success "✓ Kubernetes cluster is already running"
}
catch {
    Write-Warning-Custom "Starting Minikube cluster (this may take 1-2 minutes)..."
    minikube start --driver=docker
    
    # Wait a bit for cluster to stabilize
    Start-Sleep -Seconds 5
    
    try {
        kubectl cluster-info 2>&1 | Out-Null
        Write-Success "✓ Kubernetes cluster started successfully"
    }
    catch {
        Write-Error-Custom "Failed to start Kubernetes cluster"
        exit 1
    }
}

# Step 4: Deploy Application
Write-Info ""
Write-Info "[4/5] Deploying Application to Kubernetes..."

# Get project directory
$projectDir = Get-Location
Write-Info "Project directory: $projectDir"

# Update deployment manifest
Write-Info "Updating deployment manifest..."
$deploymentFile = Join-Path $projectDir "k8s/deployment.yaml"
$updatedFile = Join-Path $projectDir "k8s/deployment-updated.yaml"

if (-not (Test-Path $deploymentFile)) {
    Write-Error-Custom "Deployment file not found: $deploymentFile"
    exit 1
}

$deploymentContent = Get-Content $deploymentFile -Raw
$deploymentContent = $deploymentContent -replace "docker.io/USERNAME/simple-python-app:COMMIT_SHA", "docker.io/meerak1099/simple-python-app:main"
Set-Content -Path $updatedFile -Value $deploymentContent

Write-Info "Applying Kubernetes manifests..."
kubectl apply -f $updatedFile
kubectl apply -f (Join-Path $projectDir "k8s/service.yaml")

# Wait for deployment
Write-Info "Waiting for deployment to be ready..."
kubectl rollout status deployment/simple-python-app --timeout=2m

Write-Success "✓ Application deployed successfully"

# Step 5: Display Deployment Status & Capture Deliverables
Write-Info ""
Write-Info "[5/5] Deployment Status & Deliverables"
Write-Info ""

Write-Info "========== PODS =========="
$podsOutput = kubectl get pods -l app=simple-python-app
Write-Host $podsOutput
Write-Info ""

Write-Info "========== SERVICES =========="
$servicesOutput = kubectl get svc simple-python-app
Write-Host $servicesOutput
Write-Info ""

Write-Info "========== DEPLOYMENTS =========="
$deploymentsOutput = kubectl get deployments simple-python-app
Write-Host $deploymentsOutput
Write-Info ""

# Save outputs to files for documentation
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$deliverableDir = Join-Path $projectDir "deliverables"

if (-not (Test-Path $deliverableDir)) {
    New-Item -ItemType Directory -Path $deliverableDir | Out-Null
}

$podsOutput | Out-File -FilePath (Join-Path $deliverableDir "kubectl_get_pods_$timestamp.txt")
$servicesOutput | Out-File -FilePath (Join-Path $deliverableDir "kubectl_get_svc_$timestamp.txt")
$deploymentsOutput | Out-File -FilePath (Join-Path $deliverableDir "kubectl_get_deployments_$timestamp.txt")

Write-Success "✓ Outputs saved to: $deliverableDir"

# Display access information
Write-Info ""
Write-Info "========== SERVICE ACCESS =========="
Write-Info ""

$serviceName = "simple-python-app"
$serviceIP = kubectl get svc $serviceName -o jsonpath='{.spec.clusterIP}' 2>/dev/null
Write-Info "Cluster IP: $serviceIP"
Write-Info ""

Write-Info "To access the service:"
Write-Info ""
Write-Info "1. Port Forward (recommended for local testing):"
Write-Info "   kubectl port-forward svc/$serviceName 8000:80"
Write-Info ""
Write-Info "   Then access: http://localhost:8000"
Write-Info ""

Write-Info "2. Minikube Service:"
try {
    $serviceUrl = minikube service $serviceName --url 2>/dev/null
    Write-Info "   Service URL: $serviceUrl"
}
catch {
    Write-Info "   Run: minikube service $serviceName"
}
Write-Info ""

# Summary
Write-Info ""
Write-Success "========== SETUP COMPLETE =========="
Write-Info ""
Write-Info "Deliverables checklist:"
Write-Info "  ✓ Kubernetes cluster running"
Write-Info "  ✓ Application deployed (2 replicas)"
Write-Info "  ✓ Service configured"
Write-Info "  ✓ Status outputs saved to: $deliverableDir"
Write-Info ""
Write-Info "Next steps:"
Write-Info "  1. Test the application with port-forward:"
Write-Info "     kubectl port-forward svc/simple-python-app 8000:80"
Write-Info ""
Write-Info "  2. Test endpoints in another terminal:"
Write-Info "     curl http://localhost:8000/api/health"
Write-Info "     curl http://localhost:8000/api/endpoint"
Write-Info ""
Write-Info "  3. View pod logs:"
Write-Info "     kubectl logs -l app=simple-python-app"
Write-Info ""
Write-Info "  4. Clean up when done:"
Write-Info "     kubectl delete -f k8s/deployment-updated.yaml k8s/service.yaml"
Write-Info "     minikube stop"
Write-Info ""
Write-Info "Repository: https://github.com/Meerak2099/OneData-DevOps-Assessment"
Write-Info ""
