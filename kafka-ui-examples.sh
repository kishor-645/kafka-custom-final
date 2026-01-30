#!/bin/bash

# === Kafka UI Deployment Examples ===

# Example 1: Enable Kafka UI with SASL authentication
echo "📊 Example 1: Enable Kafka UI with SASL Authentication"
cat <<EOF
helm upgrade --install k1-kfk . \\
  --namespace k1 \\
  --set kafka.auth.password="secure-password-123" \\
  --set kafkaUI.enabled=true \\
  --set kafkaUI.service.type=LoadBalancer
EOF

echo ""
echo "# Then access at: http://<EXTERNAL-IP>:8080"
echo ""

# Example 2: Kafka UI with NodePort for internal access
echo "📊 Example 2: Enable Kafka UI with NodePort"
cat <<EOF
helm upgrade --install k1-kfk . \\
  --namespace k1 \\
  --set kafkaUI.enabled=true \\
  --set kafkaUI.service.type=NodePort \\
  --set kafka.auth.password="secure-password-123"
EOF

echo ""
echo "# Then access at: http://<NODE-IP>:<NODE-PORT>"
echo ""

# Example 3: Kafka UI with ClusterIP and port-forward
echo "📊 Example 3: Enable Kafka UI with ClusterIP (port-forward)"
cat <<EOF
helm upgrade --install k1-kfk . \\
  --namespace k1 \\
  --set kafkaUI.enabled=true \\
  --set kafkaUI.service.type=ClusterIP \\
  --set kafka.auth.password="secure-password-123"

# Then use port-forward:
kubectl port-forward -n k1 svc/k1-kfk-kafka-ui 8080:8080

# Access at: http://localhost:8080
EOF

echo ""

# Example 4: Check Kafka UI Pod Status
echo "📊 Example 4: Monitor Kafka UI Deployment"
cat <<EOF
# Check pod status
kubectl get pods -n k1 -l app.kubernetes.io/component=kafka-ui

# Check pod logs
kubectl logs -n k1 -l app.kubernetes.io/component=kafka-ui -f

# Check service
kubectl get svc -n k1 | grep kafka-ui

# Describe pod for troubleshooting
kubectl describe pod -n k1 -l app.kubernetes.io/component=kafka-ui
EOF

echo ""

# Example 5: Disable Kafka UI
echo "📊 Example 5: Disable Kafka UI"
cat <<EOF
helm upgrade --install k1-kfk . \\
  --namespace k1 \\
  --set kafkaUI.enabled=false
EOF

echo ""

# Example 6: Change Kafka UI replica count
echo "📊 Example 6: Scale Kafka UI (HA Mode)"
cat <<EOF
helm upgrade --install k1-kfk . \\
  --namespace k1 \\
  --set kafkaUI.enabled=true \\
  --set kafkaUI.replicaCount=3 \\
  --set kafkaUI.service.type=LoadBalancer
EOF

echo ""

# Example 7: Custom resource limits
echo "📊 Example 7: Custom Kafka UI Resources"
cat <<EOF
helm upgrade --install k1-kfk . \\
  --namespace k1 \\
  --set kafkaUI.enabled=true \\
  --set kafkaUI.resources.requests.cpu=500m \\
  --set kafkaUI.resources.requests.memory=1Gi \\
  --set kafkaUI.resources.limits.cpu=2000m \\
  --set kafkaUI.resources.limits.memory=2Gi
EOF
