# Horizontal Pod Autoscaler (HPA) and Pod Disruption Budgets (PDB) 

This repository contains a comprehensive testing framework for validating Application-Level Horizontal pod auto Scaling capabilities with different SLA workload types on Amazon EKS.

## Overview

The framework tests two distinct workload tiers:
- **Critical SLA**: High-priority workloads requiring guaranteed resources and minimal disruption
- **Standard SLA**: Cost-optimized workloads with standard resource allocation

## Architecture

```
EKS Cluster (v1.32) + Karpenter (v1.0.8)
├── Critical NodePool → Critical EC2NodeClass → Premium Instances (On-Demand)
├── Standard NodePool → Standard EC2NodeClass → General Purpose Instances (On-Demand)
├── Critical Workload + HPA (70% CPU) + PDB (80% availability)
└── Standard Workload + HPA (80% CPU) + PDB (50% availability)
```

## Prerequisites

Before deploying this testing framework, ensure you have:

1. **EKS Cluster** running version 1.32
2. **Karpenter** installed and configured (version 1.0.8)
3. **kubectl** configured to access your cluster
4. **HPA and PDB Prerequisites** (see setup options below)
5. **Proper IAM permissions** for Karpenter node provisioning
6. **Subnets and Security Groups** tagged for Karpenter discovery

### Setting Up HPA and PDB Prerequisites


#### setting up Metric server needed for HPA
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your cluster details
terraform init && terraform apply
```

### Required Tags for AWS Resources

Ensure your subnets and security groups have the following tags:
```
karpenter.sh/discovery: "YOUR_CLUSTER_NAME"
```

## File Structure

```
.
├── README.md                    # This documentation
├── terraform                    # Terraform code for setting up Metric server
├── critical-nodepool.yaml       # Critical workload NodePool
├── standard-nodepool.yaml       # Standard workload NodePool
├── critical-nodeclass.yaml      # Critical workload EC2NodeClass
├── standard-nodeclass.yaml      # Standard workload EC2NodeClass
├── critical-workload.yaml       # Critical workload deployment + service
├── standard-workload.yaml       # Standard workload deployment + service
├── critical-hpa.yaml           # Critical workload HPA configuration
├── standard-hpa.yaml           # Standard workload HPA configuration
├── critical-pdb.yaml           # Critical workload PDB configuration
├── standard-pdb.yaml           # Standard workload PDB configuration
└── generate-cpu-load.sh        # Load testing utilities
```

## Quick Start

### 1. Deploy Infrastructure

Deploy in the following order:

```bash
# Replace YOUR_CLUSTER_NAME with your actual EKS cluster name
# 1. Deploy Karpenter NodePools and EC2NodeClasses
kubectl apply -f critical-nodepool.yaml
kubectl apply -f standard-nodepool.yaml
kubectl apply -f critical-nodeclass.yaml
kubectl apply -f standard-nodeclass.yaml

# 2. Deploy workloads
kubectl apply -f critical-workload.yaml
kubectl apply -f standard-workload.yaml

# 3. Deploy HPA configurations
kubectl apply -f critical-hpa.yaml
kubectl apply -f standard-hpa.yaml

# 4. Deploy PDB configurations
kubectl apply -f critical-pdb.yaml
kubectl apply -f standard-pdb.yaml
```

## Key Features

### Critical SLA Workload
- **Instance Types**: Premium (c5.large, c5.xlarge, m5.large, m5.xlarge)
- **Capacity Type**: On-Demand only
- **HPA Target**: 70% CPU utilization
- **PDB**: 80% minimum availability
- **Scaling**: Aggressive (30s scale-up)
- **Priority**: system-cluster-critical

### Standard SLA Workload
- **Instance Types**: General purpose (t3.medium, t3.large, m5.large)
- **Capacity Type**:  (On-Demand)
- **HPA Target**: 80% CPU utilization
- **PDB**: 50% minimum availability
- **Scaling**: Standard (60s scale-up)
- **Priority**: Default

## Monitoring and Observability

### Key Metrics to Monitor
1. **Node Provisioning Time**: Time from pod scheduling to node ready
2. **HPA Response Time**: Time from threshold breach to scaling action
3. **PDB Violations**: Any disruptions that violate availability requirements
4. **Resource Utilization**: CPU/Memory usage across node tiers
5. **Cost Optimization**: Spot vs On-Demand usage in standard tier

### Useful kubectl Commands

```bash
# Monitor node provisioning
kubectl get nodes -l karpenter.sh/nodepool -w

# Watch HPA scaling
kubectl get hpa -w

# Monitor PDB status
kubectl get pdb -w

# View Karpenter events
kubectl get events --sort-by='.lastTimestamp' | grep -i karpenter

# Check workload distribution
kubectl get pods -o wide -l workload-tier=critical
kubectl get pods -o wide -l workload-tier=standard
```

## Cleanup

To remove all resources:

```bash
# Remove workloads and configurations
kubectl delete -f critical-pdb.yaml
kubectl delete -f standard-pdb.yaml
kubectl delete -f critical-hpa.yaml
kubectl delete -f standard-hpa.yaml
kubectl delete -f critical-workload.yaml
kubectl delete -f standard-workload.yaml

# Remove Karpenter resources
kubectl delete -f critical-nodeclass.yaml
kubectl delete -f standard-nodeclass.yaml
kubectl delete -f critical-nodepool.yaml
kubectl delete -f standard-nodepool.yaml

# Clean up any remaining nodes (optional)
kubectl delete nodes -l karpenter.sh/nodepool
```

## Support and Troubleshooting

- Check Karpenter controller logs: `kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter`
- Verify AWS permissions and resource tagging
- Ensure metrics-server is running for HPA functionality

## Contributing

This framework is designed to be extensible. You can:
- Add new workload types by creating additional NodePools and EC2NodeClasses
- Modify scaling parameters in HPA configurations
- Adjust PDB settings for different availability requirements
- Extend validation scripts for additional test scenarios

## License

This testing framework is provided as-is for educational and testing purposes.