# Makefile defaults
.PHONY: help usage clone pull build push all dep install uninstall status watch logs describe restart clean clean_all realm_import acmsdns_secret
.DEFAULT_GOAL := install 
.SILENT: logs usage

# Helm chart config
NAMESPACE=workbench
NAME=workbench
CHART_PATH=.

# Docker image config
APISERVER_IMAGE=ndslabs/apiserver:python
WEBUI_IMAGE=ndslabs/webui:react

# Git repo config
APISERVER_REPO=https://github.com/nds-org/workbench-apiserver-python
WEBUI_REPO=https://github.com/nds-org/workbench-webui

# Set this to empty to disable creating keycloak-realm ConfigMap
REALM_IMPORT=realm_import

define HELP_BODY
        Workbench Helm chart deployment helper Makefile

        REQUIRED CONFIG:
          - set NAME= and NAMESPACE= at top of the file to match where you want to release with Helm
          - set APISERVER_IMAGE and WEBUI_IMAGE to names of built Docker images
          - set APISERVER_REPO and WEBUI_REPO to URLs of target git repos (for Git + Docker workflows)

        OPTIONAL CONFIG:
          - enable keycloak-realm ConfigMap creating by setting REALM_IMPORT=realm_import
          - disable keycloak-realm ConfigMap creating by setting REALM_IMPORT=""

        To install Workbench:
          - `make help` or `make usage` prints this message  <-- you are here
          - <modify values.yaml locally>
          - `make realm_import` (optional: sets up the workbench-dev sample realm import for keycloak first startup)
          - `make all` to run both `make dep` and `make install`
          - `make dep` to pull Helm dependency subcharts
          - `make` or `make install` (optionally includes `make realm_import`) to perform Helm install and/or upgrade
          - `make status` or `make watch` to check Pod status or watch for changes to Pods
          - `make describe` to check Pod events for startup errors
          - `make target=api logs` or `make target=proxy logs` to check Pod logs for runtime errors

        To rebuild images locally:
          - `make clone` uses git to clone the target repos
          - `make pull` pulls existing images (sanity check)
          - <modify source locally>
          - `make push` (includes `make build`)
          - `make restart`

        To uninstall Workbench:
          - `make uninstall`
          - `make clean` (WARNING: this will delete all persistent volumes from your namespace)
          - `make clean_all` (WARNING: this will delete your entire namespace)


        Dependencies:
          - `make`
          - `helm` v3.7.0 or later (+kubeconfig)
          - `kubectl` (+kubeconfig)
          - `docker` (optional)
          - `git` (optional)

endef

#######################
# Help/Usage command  #
#######################
help:
	$(info $(HELP_BODY))

usage: help


#######################
# Git commands: clone  #
#######################
clone:
	if [ ! -d "src/" ]; then git clone $(APISERVER_REPO) src/apiserver/; git clone $(WEBUI_REPO) src/webui/; fi


#######################################
# Docker commands: pull, build, push  #
#######################################
pull:
	docker pull $(APISERVER_IMAGE)
	docker pull $(WEBUI_IMAGE)

build: clone
	docker build -t $(WEBUI_IMAGE) src/webui/
	docker build -t $(APISERVER_IMAGE) src/apiserver/

push: build
	docker push $(APISERVER_IMAGE)
	docker push $(WEBUI_IMAGE)


###########################################
# Helm commands: dep, install, uninstall  #
###########################################
all: $(REALM_IMPORT) dep install

dep:
	helm dep up

install: $(REALM_IMPORT)
	helm upgrade --install -n $(NAMESPACE) $(NAME) --create-namespace $(CHART_PATH)

uninstall:
	helm uninstall --wait -n $(NAMESPACE) $(NAME)


##############################
# kubectl (debug) commands   #
##############################
realm_import:
	kubectl create namespace $(NAMESPACE) >/dev/null 2>&1; \
	kubectl get configmaps keycloak-realm -n $(NAMESPACE) || kubectl create configmap keycloak-realm -n workbench --from-file=realm.json

acmedns_secret:
	kubectl create namespace $(NAMESPACE) >/dev/null 2>&1; \
	kubectl create secret generic acme-dns -n workbench --from-file=acmedns.json

status:
	kubectl get pods,pvc -n $(NAMESPACE)

watch:
	kubectl get pods -n $(NAMESPACE) -w

describe:
	kubectl describe pods -n $(NAMESPACE) -lcomponent=$(NAME) $(target)

logs:
	# params: target = proxy,ingress,mongo,apiserver,webui
	# syntax: $(target)
	if [ "$(target)" == "" ]; then echo 'Please specify a target: api (apiserver), ui (webui), proxy (oauth2-proxy), db (mongo, mongodb), kc (keycloak), nginx (ingress)'; echo 'Example usage: "make target=apiserver logs"'; fi
	if [ "$(target)" == "api" -o "$(target)" == "apiserver" ]; then kubectl logs -f deploy/$(NAME) -n $(NAMESPACE) -c apiserver; fi
	if [ "$(target)" == "ui" -o "$(target)" == "webui" ]; then kubectl logs -f deploy/$(NAME) -n $(NAMESPACE) -c webui; fi
	if [ "$(target)" == "proxy" -o "$(target)" == "oauth2-proxy" ]; then kubectl logs -f deploy/$(NAME)-oauth2-proxy -n $(NAMESPACE); fi
	if [ "$(target)" == "db" -o "$(target)" == "mongo" -o "$(target)" == "mongodb" ]; then kubectl logs -f deploy/$(NAME)-mongodb -n $(NAMESPACE); fi
	if [ "$(target)" == "kc" -o "$(target)" == "keycloak" ]; then kubectl logs -f $(NAME)-keycloak-0 -n $(NAMESPACE); fi
	if [ "$(target)" == "nginx" -o "$(target)" == "ingress" ]; then kubectl logs -f deploy/$(NAME)-ingress-nginx-controller -n $(NAMESPACE); fi
	#if [ "$(target)" == "proxy" -o "$(target)" == "oauth2-proxy" ]; then ; fi

restart:
	kubectl delete pod -n $(NAMESPACE) -lcomponent=$(NAME)
     
clean:
	kubectl delete pvc -n $(NAMESPACE) --all

clean_all:
	helm uninstall --wait -n $(NAMESPACE) $(NAME) > /dev/null 2>&1; \
	kubectl delete namespace $(NAMESPACE) --wait --ignore-not-found; \
	kubectl delete validatingwebhookconfigurations workbench-ingress-nginx-admission --ignore-not-found
