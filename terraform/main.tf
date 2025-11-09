# Terraform configuration for EKS cluster prerequisites
# This sets up HPA and PDB requirements including Metrics Server

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source to get EKS cluster information
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Install Metrics Server using Helm
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.11.0"

  # EKS-specific configuration to fix common issues
  set {
    name  = "args"
    value = "{--cert-dir=/tmp,--secure-port=4443,--kubelet-preferred-address-types=InternalIP\\,ExternalIP\\,Hostname,--kubelet-use-node-status-port,--kubelet-insecure-tls}"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "200Mi"
  }

  # Additional EKS-specific settings
  set {
    name  = "hostNetwork.enabled"
    value = "true"
  }

  set {
    name  = "containerPort"
    value = "4443"
  }

  # Wait for deployment to be ready
  wait = true
  timeout = 300
}



# Create priority classes for workloads
resource "kubernetes_priority_class" "critical_workload" {
  metadata {
    name = "critical-workload-priority"
  }

  value          = 1000
  global_default = false
  description    = "Priority class for critical SLA workloads"
}

resource "kubernetes_priority_class" "standard_workload" {
  metadata {
    name = "standard-workload-priority"
  }

  value          = 100
  global_default = false
  description    = "Priority class for standard SLA workloads"
}