terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.2.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  config_path = pathexpand(var.kubernetes_config_path)
}

resource "kind_cluster" "default" {
  name = "dev-cluster"
  wait_for_ready = true

  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nNodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port = 443
      }
    }

    node {
      role = "worker"
    }
  }
}