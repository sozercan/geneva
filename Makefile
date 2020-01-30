REGISTRY ?= chewong
IMAGE_NAME := mdsd
IMAGE_VERSION ?= latest
IMAGE_TAG := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION)
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

.PHONY: deploy
build:
	docker build . -t $(IMAGE_TAG)

.PHONY: push
push:
	docker push $(IMAGE_TAG)

.PHONY: clean
clean:
	@rm -f config/*.pem config/mdsd/mdsd.env $(KUSTOMIZE)
