# Kubernetes Development Environment Setup

A streamlined, automated setup for a local Kubernetes development environment using KIND (Kubernetes IN Docker), complete with essential tools and services for modern cloud-native development.

## 🚀 Features

- **Automated Cluster Setup** using Terraform and KIND
- **Pre-configured Tools & Services:**
  - ArgoCD for GitOps
  - NGINX Ingress Controller
  - Prometheus & Grafana for monitoring
  - Sample Guestbook application
- **Easy Setup** with automated scripts
- **Development Ready** with port forwarding configured

## 🛠 Prerequisites

The following tools are required:
- Docker
- Terraform
- kubectl
- Helm

You can install all prerequisites using our setup script:
```bash
sudo ./scripts/install_prerequisites.sh
```

## 🏃‍♂️ Quick Start

1. Clone the repository:
```bash
git clone https://github.com/azbndr/k8s-dev-environment-setup.git
cd k8s-dev-environment-setup
```

2. Run the setup script:
```bash
./scripts/setup.sh
```

3. Access the services:
- ArgoCD UI: http://localhost:8080 (user: admin)
- Grafana: http://localhost:3000 (user: admin)
- Guestbook: http://localhost:8081

## 📁 Repository Structure

```
.
├── k8s/                    # Kubernetes manifests
│   ├── apps/              # Application manifests
│   ├── argocd/            # ArgoCD configuration
│   ├── ingress/           # Ingress controller setup
│   └── monitoring/        # Monitoring stack configuration
├── scripts/               # Setup and utility scripts
└── terraform/             # Infrastructure as Code
```

## 🔧 Components

- **KIND Cluster**: Local Kubernetes cluster running in Docker
- **ArgoCD**: GitOps continuous delivery tool
- **NGINX Ingress**: Kubernetes ingress controller
- **Prometheus & Grafana**: Monitoring and visualization
- **Guestbook App**: Sample application for testing

## 🧪 Testing Your Setup

Run the automated test script to verify your environment:
```bash
./scripts/test-env.sh
```

The test script checks:

1. Kubernetes cluster health
2. Required namespaces (argocd, ingress-nginx, monitoring, guestbook)
3. Core services status
   - ArgoCD Server
   - NGINX Ingress Controller
   - Grafana
   - Prometheus
4. ArgoCD and Guestbook application deployment
5. Port forwarding functionality

If all tests pass, you'll see a summary and quick access commands for each service.

## 🧹 Cleanup

To clean up your development environment:

- To tear down the environment:
```bash
cd terraform
terraform destroy -auto-approve
```

## 📝 Notes

- The cluster is configured with one control plane and one worker node
- Port forwarding is automatically set up for all services
- Default credentials are provided for initial access
- Use `pkill -f 'kubectl port-forward'` to stop port forwarding

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.