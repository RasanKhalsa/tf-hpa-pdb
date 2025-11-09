# Terraform Setup for EKS HPA and PDB Prerequisites

This Terraform configuration sets up all the necessary prerequisites for running HPA (Horizontal Pod Autoscaler) and PDB (Pod Disruption Budget) on your existing EKS cluster.

## What This Terraform Configuration Does

### 🎯 Core Components
- **Metrics Server**: Installs and configures Metrics Server for HPA functionality
- **Priority Classes**: Sets up priority classes for critical and standard workloads


## Prerequisites

Before running this Terraform configuration:

1. **Existing EKS Cluster**: You must have an EKS cluster already running
2. **Terraform**: Version >= 1.0 installed
3. **AWS CLI**: Configured with appropriate permissions
4. **kubectl**: Configured to access your EKS cluster

### Required AWS Permissions

Your AWS credentials need the following permissions:
- `eks:DescribeCluster`
- `eks:ListClusters`
- Access to the EKS cluster (via aws-auth ConfigMap)

### Required Kubernetes Permissions

Your kubectl context needs cluster-admin permissions to:
- Install Helm charts
- Create cluster roles and bindings
- Create priority classes
- Create namespaces and resource quotas

## Quick Start

### 1. Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Update these required variables:
```hcl
aws_region   = "us-east-1"              # Your AWS region
cluster_name = "your-eks-cluster-name"   # Your EKS cluster name
```

### 2. Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 3. Verify Installation

```bash
# Check Metrics Server
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# Test metrics collection
kubectl top nodes

# Verify API availability
kubectl api-versions | grep -E 'autoscaling|policy'

# Check priority classes
kubectl get priorityclasses
```

## Configuration Options

### Metrics Server Configuration

```hcl
# Specific version
metrics_server_version = "3.11.0"
```



## Outputs

After successful deployment, Terraform provides:

- **Metrics Server Status**: Installation details and status
- **Cluster Info**: EKS cluster information

- **Priority Classes**: Available priority classes for workloads

## Troubleshooting

### Common Issues

#### 1. Metrics Server Not Starting

**Symptoms:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
# Shows pods in Pending or CrashLoopBackOff state
```

**Solutions:**
- Check node resources: `kubectl describe nodes`
- Verify security groups allow pod-to-pod communication
- Check Metrics Server logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=metrics-server`

#### 2. Permission Denied Errors

**Symptoms:**
```
Error: Kubernetes cluster unreachable
```

**Solutions:**
- Verify kubectl context: `kubectl config current-context`
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure you're in the aws-auth ConfigMap for the cluster

#### 3. API Version Not Available

**Symptoms:**
```bash
kubectl api-versions | grep autoscaling
# No autoscaling/v2 API found
```

**Solutions:**
- Check EKS cluster version (must be 1.23+)
- Verify cluster is healthy: `kubectl get nodes`
- Check API server logs in CloudWatch



## Cleanup

To remove all resources created by this Terraform configuration:

```bash
# Destroy all resources
terraform destroy

# Verify cleanup
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
kubectl get priorityclasses | grep workload
```


```

## Support

If you encounter issues:

1. Check the [Troubleshooting section](#troubleshooting) above
2. Review Terraform logs: `terraform apply -debug`
3. Check Kubernetes events: `kubectl get events --sort-by='.lastTimestamp'`
4. Verify EKS cluster health in AWS Console

## Next Steps

After successful deployment:

1. **Deploy Karpenter workload testing manifests**
2. **Run HPA validation tests**
3. **Test PDB protection scenarios**
4. **Monitor metrics and scaling behavior**

The cluster is now ready for comprehensive Karpenter workload testing with HPA and PDB functionality!