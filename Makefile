REGISTRY ?= chewong
MDSD_IMAGE_NAME := mdsd
MDSD_IMAGE_VERSION ?= latest
MDSD_IMAGE_TAG := $(REGISTRY)/$(MDSD_IMAGE_NAME):$(MDSD_IMAGE_VERSION)
METRICS_IMAGE_NAME := geneva-metrics
METRICS_IMAGE_VERSION ?= latest
METRICS_IMAGE_TAG := $(REGISTRY)/$(METRICS_IMAGE_NAME):$(MDSD_IMAGE_VERSION)
KUSTOMIZE := $(PWD)/kustomize
GENEVA_METRICS_CONTAINER_NAME := geneva-metrics
ifdef JOB_ID
GENEVA_METRICS_CONTAINER_NAME := $(GENEVA_METRICS_CONTAINER_NAME)-$(JOB_ID)
endif
VAULT_NAME ?= geneva-certs
VAULT_CERT_NAME ?= azcu-geneva-logs-test
GENEVA_METRICS_STAMP_URL ?= https://az-compute.metrics.nsatc.net/

.PHONY: download-kustomize
download-kustomize:
	curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash || true

.PHONY: download-certs
download-certs:
	az keyvault secret download --vault-name $(VAULT_NAME) -n $(VAULT_CERT_NAME) -e base64 -f cert.pfx
	openssl pkcs12 -nocerts -nodes -passin pass: -in cert.pfx -out gcskey.pem && openssl rsa -in gcskey.pem -out config/gcskey.pem
	openssl pkcs12 -nokeys -nodes -passin pass: -in cert.pfx -out gcscert.pem && openssl x509 -in gcscert.pem -out config/gcscert.pem
	rm gcskey.pem gcscert.pem cert.pfx

.PHONY: mdsd-env
mdsd-env:
ifeq ($(and $(strip $(MONITORING_ROLE_INSTANCE)),$(strip $(MONITORING_GCS_ENVIRONMENT)),$(strip $(MONITORING_GCS_ACCOUNT)),$(strip $(MONITORING_GCS_REGION)),$(strip $(MONITORING_TENANT)),$(strip $(MONITORING_ROLE))),)
	$(error Required monitoring variables are not defined)
endif
	@echo 'MONITORING_ROLE_INSTANCE=$(MONITORING_ROLE_INSTANCE)' > config/mdsd/mdsd.env
	@echo 'MONITORING_GCS_ENVIRONMENT=$(MONITORING_GCS_ENVIRONMENT)' >> config/mdsd/mdsd.env
	@echo 'MONITORING_GCS_ACCOUNT=$(MONITORING_GCS_ACCOUNT)' >> config/mdsd/mdsd.env
	@echo 'MONITORING_GCS_REGION=$(MONITORING_GCS_REGION)' >> config/mdsd/mdsd.env
	@echo 'MONITORING_TENANT=$(MONITORING_TENANT)' >> config/mdsd/mdsd.env
	@echo 'MONITORING_ROLE=$(MONITORING_ROLE)' >> config/mdsd/mdsd.env

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
		--name $(GENEVA_METRICS_CONTAINER_NAME) \
		$(METRICS_IMAGE_TAG) \
		MetricsExtension -Logger Console -FrontEndUrl $(GENEVA_METRICS_STAMP_URL) -CertFile /etc/certs/gcscert.pem -PrivateKeyFile /etc/certs/gcskey.pem -Input statsd_udp

.PHONY: clean
clean:
	@rm -f config/*.pem config/mdsd/mdsd.env $(KUSTOMIZE)
