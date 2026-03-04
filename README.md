# Simple Python Application

[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/simple-python-app/actions/workflows/ci-cd.yml/badge.svg?branch=main)](https://github.com/YOUR_USERNAME/simple-python-app/actions/workflows/ci-cd.yml)

This is a simple Python Flask application that demonstrates the use of unit testing, Docker containerization, and Kubernetes deployment. The application includes REST API endpoints with health checks and utility functions, all tested using unit tests.

## Features

- RESTful API endpoints with Flask
- Health check endpoint (`/api/health`)
- Unit tests for all functionality (3+ tests)
- Comprehensive linting with pylint and flake8
- Dockerized application with optimized layering
- GitHub Actions CI/CD pipeline with:
  - Separate checkout, lint, test, build, and deploy jobs
  - Docker image tagging with Git commit SHA
  - Automatic deployment to Kubernetes
  - Manual approval gate for production deployments
  - Integration tests against deployed service
  - Automatic rollback on deployment failure
- Kubernetes deployment manifests with probes
- Deployment to local Kubernetes cluster (Minikube or kind)

## API Endpoints

- `GET /api/health` - Health check endpoint
- `GET /api/endpoint` - Returns data with expected_key
- `POST /api/endpoint` - Accepts JSON data and returns received data

## Project Structure

```
simple-python-app
├── app
│   ├── __init__.py
│   └── main.py
├── tests
│   ├── test_api.py           # API endpoint tests
│   ├── test_health.py        # Health check tests
│   └── test_utils.py         # Utility function tests
├── scripts
│   └── integration-tests.sh  # Integration tests script
├── k8s
│   ├── deployment.yaml       # Kubernetes Deployment manifest
│   └── service.yaml          # Kubernetes Service manifest
├── .github
│   └── workflows
│       └── ci-cd.yml         # GitHub Actions CI/CD workflow
├── Dockerfile
├── .dockerignore
├── requirements.txt
├── pyproject.toml
├── Makefile
└── README.md
```

## Prerequisites

- Python 3.9+
- Docker
- Kubernetes cluster (Minikube, kind, or cloud provider)
- kubectl configured with cluster access
- GitHub repository with Actions enabled

## Setup Instructions

### 1. Local Development

Clone the repository:
```bash
git clone https://github.com/yourusername/simple-python-app.git
cd simple-python-app
```

Install dependencies:
```bash
pip install -r requirements.txt
```

Run the application locally:
```bash
python -m app.main
```

The app will be available at `http://localhost:8000`

### 2. Running Tests

Run unit tests:
```bash
pytest tests/ -v
```

Run linting:
```bash
pylint app/
flake8 app/
```

### 3. Docker Build

Build the Docker image:
```bash
docker build -t simple-python-app:latest .
```

Run in Docker:
```bash
docker run -p 8000:8000 simple-python-app:latest
```

### 4. Kubernetes Deployment

Ensure you have Minikube or kind running:
```bash
# For Minikube
minikube start

# Or for kind
kind create cluster
```

Update the deployment manifest with your image registry:
```bash
sed -i 's|ghcr.io/USERNAME|ghcr.io/yourusername|g' k8s/deployment.yaml
```

Apply the manifests:
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Check deployment status:
```bash
kubectl get deployments
kubectl get pods -l app=simple-python-app
kubectl get svc simple-python-app
```

## CI/CD Pipeline Details

### Workflow Stages

1. **Checkout** - Pulls the latest code from the repository
2. **Lint** - Runs pylint and flake8 code quality checks
3. **Unit Test** - Executes all unit tests with pytest
4. **Build** - Builds Docker image and pushes to GHCR
5. **Deploy (with Approval)** - Deploys to Kubernetes with manual approval gate
6. **Integration Tests** - Runs tests against the deployed service
7. **Rollback** - Automatically undoes deployment if tests fail

### Image Tagging Strategy

Docker images are tagged with:
- Git commit SHA: `ghcr.io/username/simple-python-app:sha-abc123def456`
- Branch names: `ghcr.io/username/simple-python-app:main`
- Semantic versions: `ghcr.io/username/simple-python-app:v1.0.0`

This ensures every deployment is traceable to a specific commit.

### GitHub Environment Configuration

The deployment job uses a GitHub Environment named `staging` with:
- Manual approval required before deployment
- Required reviewers can be configured in repository settings
- Deployment history is tracked

To configure:
1. Go to repository Settings → Environments
2. Create/edit `staging` environment
3. Add required reviewers under "Deployment branches"

### Secrets Configuration

The workflow requires these GitHub Secrets:
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions (for GHCR access)

Optional for additional registries:
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub personal access token

## Troubleshooting

### Pod won't start
```bash
kubectl logs -l app=simple-python-app
kubectl describe pod <pod-name>
```

### Service not accessible
```bash
# Check service endpoints
kubectl get endpoints simple-python-app

# For Minikube, access via:
minikube service simple-python-app
```

### Build failures
Check the GitHub Actions logs in the repository's Actions tab:
- Workflow run details
- Failed job logs
- Error messages and stack traces

### Deployment rollback
If deployment fails, the workflow automatically triggers rollback:
```bash
# Manual rollback
kubectl rollout undo deployment/simple-python-app

# View rollout history
kubectl rollout history deployment/simple-python-app
```

## Example Deployment Output

```bash
$ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
simple-python-app-5d4f8b7c6-abc12      1/1     Running   0          2m
simple-python-app-5d4f8b7c6-def34      1/1     Running   0          2m

$ kubectl get svc
NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
simple-python-app    LoadBalancer   10.96.100.200    localhost     80:32000/TCP   2m

$ curl http://localhost/api/health
{"status":"healthy"}
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## References

- [Flask Documentation](https://flask.palletsprojects.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)