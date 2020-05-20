# Geneva

A collection of images and Kubernetes manifests that send logs and metrics to Geneva.

## Quickstart

```bash
az login
export MONITORING_ROLE_INSTANCE=<your cluster name>
export MONITORING_GCS_ENVIRONMENT=<geneva environment>
export MONITORING_GCS_ACCOUNT=<geneva account>
export MONITORING_GCS_REGION=<region>
export MONITORING_TENANT=<tenant>
export MONITORING_ROLE=<role>
make deploy
kubectl get pod --namespace monitoring
```

## Build Linux Monitoring Agent (MDSD) Image

`REGISTRY=<your Dockerhub username> IMAGE_VERSION=<image version> make image-mdsd push-mdsd`

## Debug MDSD

```bash
# Get fluent-bit-geneva-logging pod name
kubectl get pod --namespace monitoring
kubectl exec -it fluent-bit-geneva-logging-xxxxx --namespace monitoring --container mdsd /bin/sh
# Print stdout of mdsd
cat /var/log/mdsd.info
# Print stderr of mdsd
cat /var/log/mdsd.err
```

## Build Geneva Metrics Image

`REGISTRY=<your Dockerhub username> IMAGE_VERSION=<image version> make image-metrics push-metrics`

## Useful Links

- [Fluent Bit](https://docs.fluentbit.io/manual/)
- [Fluent Bit Kubernetes Filter Plugin](https://docs.fluentbit.io/manual/filter/kubernetes)
