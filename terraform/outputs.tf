# Outputs for EKS HPA/PDB setup

output "metrics_server_status" {
  description = "Status of the Metrics Server installation"
  value = {
    name      = helm_release.metrics_server.name
    namespace = helm_release.metrics_server.namespace
    version   = helm_release.metrics_server.version
    status    = helm_release.metrics_server.status
  }
}

output "cluster_info" {
  description = "EKS cluster information"
  value = {
    cluster_name     = var.cluster_name
    cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
    cluster_version  = data.aws_eks_cluster.cluster.version
    region          = var.aws_region
  }
}



output "priority_classes" {
  description = "Created priority classes"
  value = {
    critical_workload = {
      name  = kubernetes_priority_class.critical_workload.metadata[0].name
      value = kubernetes_priority_class.critical_workload.value
    }
    standard_workload = {
      name  = kubernetes_priority_class.standard_workload.metadata[0].name
      value = kubernetes_priority_class.standard_workload.value
    }
  }
}

output "validation_commands" {
  description = "Commands to validate the setup"
  value = {
    check_metrics_server = "kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server"
    check_hpa_api       = "kubectl api-versions | grep autoscaling"
    check_pdb_api       = "kubectl api-versions | grep policy"
    test_metrics        = "kubectl top nodes"
    check_priority      = "kubectl get priorityclasses"
  }
}

output "next_steps" {
  description = "Next steps after Terraform deployment"
  value = [
    "1. Verify Metrics Server is running: kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server",
    "2. Test metrics collection: kubectl top nodes",
    "3. Check API availability: kubectl api-versions | grep -E 'autoscaling|policy'",
    "4. Deploy your Karpenter workload testing manifests",
    "5. Run validation scripts to test HPA and PDB functionality"
  ]
}