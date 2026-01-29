#!/bin/bash

# === Input Configuration ===
ENV_PREFIX=${1:-"k"}
NAMESPACE="${ENV_PREFIX}"
# Make sure the Release Name is short to avoid label truncation issues
RELEASE_NAME="${ENV_PREFIX}-kfk"
CHART_PATH="." # Path to your local folder

# Updated HA Strategy for this specific chart
CONTROLLER_COUNT=1  # MUST BE 1 (Chart limitation)
BROKER_COUNT=3      # High Availability for data
STORAGE_CLASS="longhorn"
IMAGE_REPO="apache/kafka"
IMAGE_TAG="3.8.0"

# === 1. Safety Check ===
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    echo "❌ Error: Could not find Chart.yaml in '$CHART_PATH'. Are you in the right folder?"
    exit 1
fi

echo "------------------------------------------------------------------"
echo "🚀 Deploying Vanilla Kafka (Data HA Mode)"
echo "📍 Namespace:  $NAMESPACE"
echo "🏗️  Setup:      1 Controller (Metadata) / 3 Brokers (Data)"
echo "------------------------------------------------------------------"

# === 2. Namespace Preparation ===
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

# === 3. Helm Upgrade / Install ===
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" \
  --set kafka.image.repository="$IMAGE_REPO" \
  --set kafka.image.tag="$IMAGE_TAG" \
  --set kafka.controller.replicaCount=$CONTROLLER_COUNT \
  --set kafka.controller.persistence.storageClass="$STORAGE_CLASS" \
  --set kafka.controller.persistence.size="5Gi" \
  --set kafka.broker.replicaCount=$BROKER_COUNT \
  --set kafka.broker.persistence.storageClass="$STORAGE_CLASS" \
  --set kafka.broker.persistence.size="50Gi" \
  --set kafka.broker.resources.requests.memory="1Gi" \
  --set kafka.broker.resources.limits.memory="2Gi" \
  --set exporters.kafka.enabled=true

# === 4. Sequential Readiness Check ===
echo "⏳ Checking Controller status..."
kubectl rollout status statefulset/"${RELEASE_NAME}-controller" -n "$NAMESPACE" --timeout=300s

if [ $? -eq 0 ]; then
    echo "✅ Controller is stable."
    echo "⏳ Checking 3-Node Broker Cluster status..."
    # The chart usually names the broker statefulset like this:
    kubectl rollout status statefulset/"${RELEASE_NAME}-broker" -n "$NAMESPACE" --timeout=300s
else
    echo "❌ Controller failed to start."
    exit 1
fi

# === 5. Final Status ===
if [ $? -eq 0 ]; then
    echo "------------------------------------------------------------------"
    echo "✅ Success: Kafka is RUNNING with 3 data-replicas."
    echo "🔗 Bootstrap: ${RELEASE_NAME}-broker.${NAMESPACE}.svc.cluster.local:9092"
    echo "------------------------------------------------------------------"
else
    echo "❌ Broker cluster failed to stabilize."
    exit 1
fi