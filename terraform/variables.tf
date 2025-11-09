# Variables for EKS HPA/PDB setup

variable "aws_region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name must not be empty."
  }
}

variable "metrics_server_version" {
  description = "Version of the Metrics Server Helm chart"
  type        = string
  default     = "3.11.0"
}



