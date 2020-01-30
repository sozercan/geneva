# fluent-bit-geneva-logging

## Quickstart

1. Download [kustomize](https://github.com/kubernetes-sigs/kustomize) and [azure-cli](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest).
2. `az login`
3. `make deploy`
4. `kubectl get pods --namespace monitoring`

## Build Linux monitoring agent image

`make image push`
