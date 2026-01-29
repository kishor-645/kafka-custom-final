#!/bin/bash

# === Input Configuration ===
ENV_PREFIX=${1:-"internal"}
NAMESPACE="${ENV_PREFIX}"
RELEASE_NAME="${ENV_PREFIX}-kfk-test"
CHART_PATH="." # Path to the unzipped local chart folder

# Global Defaults (High Availability)
REPLICA_COUNT=3  # Always 3 for Controllers and Brokers
STORAGE_CLASS="longhorn"
IMAGE_REPO="apache/kafka"
IMAGE_TAG="3.8.0"

# === 1. Safety Check ===
if [ ! -d "$CHART_PATH" ]; then
    echo "❌ Error: Local helm chart directory '$CHART_PATH' not found."
    exit 1
fi

echo "------------------------------------------------------------------"
echo "🚀 Deploying High-Availability Vanilla Kafka"
echo "📍 Namespace:  $NAMESPACE"
echo "🏗️  Replicas:   3 Controllers / 3 Brokers"
echo "🖼️  Image:      $IMAGE_REPO:$IMAGE_TAG"
echo "------------------------------------------------------------------"

# === 2. Namespace Preparation ===
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

# === 3. Helm Upgrade / Install ===
# This set specifically maps to the 'cagriekin/kafka' structure
# using 3 replicas as the absolute default for HA stability.
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" \
  --set kafka.image.repository="$IMAGE_REPO" \
  --set kafka.image.tag="$IMAGE_TAG" \
  --set kafka.controller.replicaCount=$REPLICA_COUNT \
  --set kafka.controller.persistence.storageClass="$STORAGE_CLASS" \
  --set kafka.controller.persistence.size="5Gi" \
  --set kafka.broker.replicaCount=$REPLICA_COUNT \
  --set kafka.broker.persistence.storageClass="$STORAGE_CLASS" \
  --set kafka.broker.persistence.size="50Gi" \
  --set kafka.broker.resources.requests.memory="2Gi" \
  --set kafka.broker.resources.limits.memory="4Gi" \
  --set exporters.kafka.enabled=true \
  --set serviceMonitors.enabled=true

# === 4. Sequential Readiness Check ===
echo "⏳ Checking Controller Quorum stability..."
kubectl rollout status statefulset/"${RELEASE_NAME}-controller" -n "$NAMESPACE" --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ Controller Quorum established."
    echo "⏳ Checking Broker Cluster status..."
    kubectl rollout status statefulset/"${RELEASE_NAME}-broker" -n "$NAMESPACE" --timeout=300s
else
    echo "❌ Controller Quorum failed to stabilize."
    exit 1
fi

# === 5. Final Status ===
if [ $? -eq 0 ]; then
    echo "------------------------------------------------------------------"
    echo "✅ Success: HA Kafka Cluster '$RELEASE_NAME' is fully RUNNING."
    echo "🔗 Internal Bootstrap: ${RELEASE_NAME}-broker.${NAMESPACE}.svc.cluster.local:9092"
    echo "📊 Monitoring: ServiceMonitor created in ${NAMESPACE}"
    echo "------------------------------------------------------------------"
else
    echo "❌ Deployment encountered issues. Check logs via: kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=kafka"
    exit 1
fi