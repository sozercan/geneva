# fluent-bit-geneva-logging

## Quickstart

```bash
az login
MONITORING_ROLE_INSTANCE=<your cluster name> make deploy
kubectl get pod --namespace monitoring
```

## Build Linux Monitoring Agent (MDSD) Image

`REGISTRY=<your Dockerhub username> IMAGE_VERSION=<image version> make image push`

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

## Useful Links

- [Fluent Bit](https://docs.fluentbit.io/manual/)
- [Fluent Bit Kubernetes Filter Plugin](https://docs.fluentbit.io/manual/filter/kubernetes)
