#!/bin/bash

# === Input Configuration ===
ENV_PREFIX=${1:-"k"}
NAMESPACE="${ENV_PREFIX}"
# Make sure the Release Name is short to avoid label truncation issues
RELEASE_NAME="${ENV_PREFIX}-stackforge-kfk"
CHART_PATH="." # Path to your local folder

# Updated HA Strategy for this specific chart
STORAGE_CLASS="longhorn"

# === 1. Safety Check ===
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    echo " Error: Could not find Chart.yaml in '$CHART_PATH'. Are you in the right folder?"
    exit 1
fi

echo "------------------------------------------------------------------"
echo "Deploying Vanilla Kafka (Data HA Mode)"
echo "Namespace:  $NAMESPACE"

# === 2. Namespace Preparation ===
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

# === 3. Helm Upgrade / Install ===
helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  --namespace "$NAMESPACE" \
  --set kafka.controller.persistence.storageClass="$STORAGE_CLASS" \
  --set kafka.controller.persistence.size="1Gi" \
  --set kafka.broker.persistence.storageClass="$STORAGE_CLASS" \
  --set kafka.broker.persistence.size="1Gi" \
  --set kafka.broker.replicaCount=1 \
  --set kafka.broker.resources.requests.memory="1Gi" \
  --set kafka.broker.resources.limits.memory="2Gi" \
  --set kafka.broker.service.loadBalancerIP="10.227.252.62" \
  --set kafka.broker.listeners.internalName="INTERNAL" \
  --set kafka.broker.listeners.externalName="EXTERNAL" \
  --set kafka.broker.listeners.internalPort=9092 \
  --set kafka.broker.listeners.externalPort=9094 \
  --set kafka.broker.externalAdvertisedHost="10.227.252.62" \
  --set kafkaUI.enabled=true
    
