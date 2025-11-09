#!/bin/bash

# Simple CPU Load Generator for HPA Testing
# This generates CPU load directly in the workload pods

set -e

echo "=== CPU Load Generator for HPA Testing ==="
echo

# Check if metrics-server is working
echo "Checking metrics-server..."
if ! kubectl top nodes &>/dev/null; then
    echo "❌ Metrics server is not responding. HPA will not work!"
    echo "Please ensure metrics-server is installed and running."
    exit 1
fi
echo "✅ Metrics server is working"
echo

# Function to start CPU stress in all pods of a deployment
stress_deployment() {
    local app_label=$1
    local cpu_threads=${2:-2}
    local duration=${3:-300}
    
    echo "Starting CPU stress for app=$app_label (${cpu_threads} threads, ${duration}s duration)"
    
    local pods=$(kubectl get pods -l app=$app_label -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$pods" ]; then
        echo "❌ No pods found for app=$app_label"
        return 1
    fi
    
    for pod in $pods; do
        echo "  → Stressing pod: $pod"
        # Start multiple CPU-intensive processes in background
        for i in $(seq 1 $cpu_threads); do
            kubectl exec $pod -- sh -c "timeout ${duration}s sh -c 'while true; do echo \$((2**20)) > /dev/null; done' &" 2>/dev/null || true
        done
    done
    
    echo "✅ CPU stress started for $app_label"
}

# Show current state
echo "Current HPA status:"
kubectl get hpa
echo

echo "Current pod resource usage:"
kubectl top pods -l app=critical-workload 2>/dev/null || echo "  (metrics not available yet)"
kubectl top pods -l app=standard-workload 2>/dev/null || echo "  (metrics not available yet)"
echo

# Start CPU stress
echo "Starting CPU stress tests..."
echo "This will run for 5 minutes (300 seconds)"
echo

stress_deployment "critical-workload" 3 300
echo
stress_deployment "standard-workload" 3 300
echo

echo "✅ CPU stress started in all pods!"
echo
echo "Now monitoring HPA scaling..."
echo "You should see:"
echo "  1. CPU usage increase in 'kubectl top pods'"
echo "  2. HPA TARGETS column show increasing CPU %"
echo "  3. REPLICAS count increase when CPU exceeds threshold"
echo "  4. New pods being created"
echo
echo "Run this command to monitor:"
echo "  watch -n 5 'kubectl get hpa && echo && kubectl top pods'"
echo
echo "Or use this for detailed monitoring:"
cat << 'MONITOR'
while true; do
  clear
  echo "=== HPA Status ($(date)) ==="
  kubectl get hpa
  echo
  echo "=== Pod CPU Usage ==="
  kubectl top pods -l app=critical-workload 2>/dev/null || echo "Metrics not ready"
  kubectl top pods -l app=standard-workload 2>/dev/null || echo "Metrics not ready"
  echo
  echo "=== Pod Counts ==="
  echo "Critical: $(kubectl get pods -l app=critical-workload --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) running"
  echo "Standard: $(kubectl get pods -l app=standard-workload --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) running"
  sleep 10
done
MONITOR
