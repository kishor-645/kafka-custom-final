# Kafka KRaft Helm Chart

This chart deploys an Apache Kafka **KRaft** cluster (controller + brokers) with optional Kafka UI and Kafka Exporter. It is designed for internal, Kubernetes DNS-based access (no broker LoadBalancer service).

## Features

- **KRaft Mode:** Separate controller and broker StatefulSets (no ZooKeeper)
- **Stateful Storage:** PersistentVolumeClaims for controller and broker data
- **Security-Ready:** Optional SASL/PLAIN auth with secrets
- **Observability:** Optional Kafka Exporter and Prometheus ServiceMonitor
- **Declarative Topics:** Topic init job with metadata-driven docs
- **Kafka UI:** Optional UI for cluster inspection and topic management
- **Network Policy:** Optional ingress/egress restrictions

---

## Components

- Kafka controller StatefulSet (single controller node)
- Kafka broker StatefulSet (configurable replica count)
- ConfigMaps for runtime configuration
- Optional SASL secret for credentials
- Topic initialization job
- Kafka Exporter Deployment + Service (optional)
- Kafka UI Deployment + Service (optional)

---

## Configuration Parameters

Key values are summarized below. See `values.yaml` for the full list.

| Parameter | Description | Default |
| --- | --- | --- |
| `fullnameOverride` | Base name applied to every resource | `""` |
| `kafka.controller.replicaCount` | KRaft controller replicas | `1` |
| `kafka.broker.replicaCount` | Broker replicas | `2` |
| `kafka.controller.persistence.storageClass` | Controller PVC storage class | `longhorn-fast` |
| `kafka.broker.persistence.storageClass` | Broker PVC storage class | `longhorn-fast` |
| `kafka.auth.enabled` | Enable SASL/PLAIN authentication | `false` |
| `kafka.auth.username` | SASL username | `user1` |
| `kafka.auth.password` | SASL password | `kafka-secure-password-123` |
| `kafka.autoCreateTopicsEnable` | Auto-create topics | `true` |
| `kafka.deleteTopicEnable` | Allow topic deletion | `true` |
| `kafka.topics` | Declarative topic definitions | `{}` |
| `exporters.kafka.enabled` | Enable Kafka Exporter | `true` |
| `serviceMonitors.enabled` | Enable Prometheus ServiceMonitor | `false` |
| `kafkaUI.enabled` | Enable Kafka UI | `false` |
| `kafkaUI.service.type` | Kafka UI Service type | `LoadBalancer` |
| `networkPolicy.enabled` | Enable NetworkPolicies | `true` |

---

## Installation Guide

### 1. Minimal Configuration (Internal DNS Only)

```bash
helm upgrade --install k1-kfk . \
  --namespace k1 \
  --create-namespace \
  --set kafka.auth.enabled=false
```

### 2. Production Configuration (Auth + Storage + UI)

```bash
helm upgrade --install k1-kfk . \
  --namespace k1 \
  --create-namespace \
  --set kafka.auth.enabled=true \
  --set kafka.auth.password="StrongPassword123" \
  --set kafka.controller.persistence.storageClass="longhorn" \
  --set kafka.broker.persistence.storageClass="longhorn" \
  --set kafkaUI.enabled=true
```

### 3. Deploy Using `deploy-kafka.sh`

This repo includes a helper script that wraps the recommended Helm install.

```bash
./deploy-kafka.sh <namespace>
```

Example:

```bash
./deploy-kafka.sh k4
```

---

## Accessing Kafka

This chart **does not expose brokers via LoadBalancer**. Brokers are reachable **only inside the cluster** using Kubernetes DNS:

```
<broker-pod>.<release>-kafka-broker.<namespace>.svc.cluster.local:9092
```

Example:

```
k4-kfk-kafka-kafka-broker-0.k4-kfk-kafka-kafka-broker.k4.svc.cluster.local:9092
```

For external access, use one of the following (not included by default):

- Port-forward a broker pod
- Create a custom ingress or gateway
- Use a separate Kafka proxy

---

## Topic Management

Define topics in `values.yaml` under `kafka.topics`. Each topic can include metadata for documentation.

Example:

```yaml
kafka:
  topics:
    user-events:
      partitions: 3
      replicationFactor: 1
      metadata:
        description: User lifecycle events
        producers:
          - webapp
        consumers:
          - audit-service
```

The topic init job runs on install/upgrade to reconcile topic settings.

---

## Verification & Troubleshooting

### Check Pods

```bash
kubectl get pods -n <namespace>
```

### Check Broker Service

```bash
kubectl get svc -n <namespace>
```

### Broker DNS Test (Inside Cluster)

```bash
kubectl exec -n <namespace> -it <broker-pod> -- /bin/sh
# then from inside the pod:
nslookup <broker-pod>.<release>-kafka-broker.<namespace>.svc.cluster.local
```

### Kafka UI Access

If Kafka UI is enabled:

```bash
kubectl get svc -n <namespace> | grep kafka-ui
```

- For LoadBalancer: `http://<EXTERNAL-IP>:<port>`
- For ClusterIP: use port-forward

```bash
kubectl port-forward -n <namespace> svc/<release>-kafka-ui 8080:80
```

---

## Notes

- **Controller replicas** are currently fixed at `1` for KRaft.
- **Auth defaults to disabled**. Enable SASL when needed.
- **Storage class** must exist in your cluster (check `kubectl get sc`).
- **Kafka UI** uses internal DNS and is intended for in-cluster access.
