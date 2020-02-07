REGISTRY ?= chewong
MDSD_IMAGE_NAME := mdsd
MDSD_IMAGE_VERSION ?= latest
MDSD_IMAGE_TAG := $(REGISTRY)/$(MDSD_IMAGE_NAME):$(MDSD_IMAGE_VERSION)
METRICS_IMAGE_NAME := geneva-metrics
METRICS_IMAGE_VERSION ?= latest
METRICS_IMAGE_TAG := $(REGISTRY)/$(METRICS_IMAGE_NAME):$(MDSD_IMAGE_VERSION)
KUSTOMIZE := $(PWD)/kustomize

.PHONY: download-kustomize
download-kustomize:
	curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash || true

.PHONY: download-certs
download-certs:
	az keyvault secret download --vault-name geneva-certs -n azcu-geneva-logs-test -e base64 -f cert.pfx
	openssl pkcs12 -nocerts -nodes -passin pass: -in cert.pfx -out gcskey.pem && openssl rsa -in gcskey.pem -out config/gcskey.pem
	openssl pkcs12 -nokeys -nodes -passin pass: -in cert.pfx -out gcscert.pem && openssl x509 -in gcscert.pem -out config/gcscert.pem
	rm gcskey.pem gcscert.pem cert.pfx

.PHONY: mdsd-env
mdsd-env:
ifeq ($(MONITORING_ROLE_INSTANCE),)
	$(error MONITORING_ROLE_INSTANCE is not defined)
endif
	@echo 'MONITORING_ROLE_INSTANCE=$(MONITORING_ROLE_INSTANCE)' > config/mdsd/mdsd.env

.PHONY: deploy
deploy: download-kustomize mdsd-env download-certs
	$(KUSTOMIZE) build config/ | kubectl apply -f -

.PHONY: undeploy
undeploy:
	$(KUSTOMIZE) build config/ | kubectl delete -f -

.PHONY: image-mdsd
image-mdsd:
	docker build . -f Dockerfile.mdsd -t $(MDSD_IMAGE_TAG)

.PHONY: push-mdsd
push-mdsd:
	docker push $(MDSD_IMAGE_TAG)

.PHONY: image-metrics
image-metrics:
	docker build . -f Dockerfile.metrics -t $(METRICS_IMAGE_TAG)

.PHONY: push-metrics
push-metrics:
	docker push $(METRICS_IMAGE_TAG)

.PHONY: run-metrics
run-metrics: download-certs
	docker run \
		-d \
		-v $(PWD)/config/gcscert.pem:/etc/certs/gcscert.pem \
		-v $(PWD)/config/gcskey.pem:/etc/certs/gcskey.pem \
		--rm \
		--name geneva-metrics \
		$(METRICS_IMAGE_TAG) \
		MetricsExtension -Logger Console -FrontEndUrl https://az-compute.metrics.nsatc.net -CertFile /etc/certs/gcscert.pem -PrivateKeyFile /etc/certs/gcskey.pem -Input statsd_udp

.PHONY: clean
clean:
	@rm -f config/*.pem config/mdsd/mdsd.env $(KUSTOMIZE)
