# Makefile defaults
.PHONY: $(MAKECMDGOALS)
.DEFAULT_GOAL := install 
.SILENT: logs usage help check_helm check_kubectl check_git check_docker check_yarn check_all check_required check_optional

# Import configuration from .env
include .env
export

# Set this to empty to disable creating keycloak-realm ConfigMap
#REALM_IMPORT=

define HELP_BODY
        Workbench Helm chart deployment helper Makefile

        Dependencies:
          - `make`
          - `helm` v3.7.0 or later (+kubeconfig)
          - `kubectl` (+kubeconfig)
          - `docker` (optional)
          - `git` (optional)
          - `yarn` (optional)

        OPTIONAL CONFIG (see .env):
          - change NAME= and NAMESPACE= to match where you want to release with Helm (default: workbench)
          - set APISERVER_IMAGE and WEBUI_IMAGE to names of target names of Docker images
          - set APISERVER_REPO and WEBUI_REPO to URLs of target git repos (for local chart development)
          - set APISERVER_UPSTREAM_BRANCH and WEBUI_UPSTREAM_BRANCH to names of target git branches (default: main, for local chart development)
          - enable keycloak-realm ConfigMap creating by setting REALM_IMPORT=realm_import
          - disable keycloak-realm ConfigMap creating by setting REALM_IMPORT=""

        General Usage:
          - `make check_all` ensure that all dependencies are installed and ready
          - `make help` or `make usage` prints this message  <-- you are here

        To install Workbench:
          - <modify values.yaml locally>
          - `make all` to run both `make dep` and `make install`
          - `make dep` to pull Helm dependency subcharts
          - `make template` to perform a dry-run of Helm chart generation (for debugging)
          - `make` or `make install` to perform Helm install and/or upgrade (optionally includes `make realm_import`, enabled by default)
          - `make status` or `make watch` to check status or watch for changes to Pods
          - `make describe` to check Pod events for startup errors
          - `make target=api logs` or `make target=proxy logs` to check Pod logs for runtime errors

        To rebuild images locally:
          - `make clone` uses git to clone the target repos
          - `make pull` pulls upstream Git changes (sanity check)
          - <modify source locally>
          - `make compile` uses yarn to locally recompile the webui source code
          - `make push` (includes `make build`) to push newly-built Docker images
          - `make restart` will delete the running Pod so one is started running the new images

        To uninstall Workbench:
          - `make uninstall`
          - `make clean` (WARNING: DEBUG ONLY - this will delete all persistent volumes from your namespace)
          - `make clean_all` (WARNING: DEBUG ONLY - this will delete your entire namespace)

        Misc functions:
          - `make realm_import` (optional, enabled by default: creates a ConfigMap that can be mounted into keycloak to import a test realm)
          - `make acmedns_secret` (optional: creates a Secret that can be loaded into cert-manager for use by ACMEDNS)

        
endef


########################
# Help/Usage commands  #
########################
help:
	$(info $(HELP_BODY))

usage: help


########################
# Dependency Checks    #
########################
check_all: check_required check_optional
	echo "$(SUCCESS) all dependencies are installed and ready."

check_required: check_kubectl check_helm
	echo "$(SUCCESS) all reauired dependencies are installed and ready."

check_optional: check_git check_docker check_yarn
	echo "$(SUCCESS) all optional dependencies are installed and ready."

check_kubectl:
	which -s kubectl || (echo '$(FAILED) Please install kubectl to use this Helm chart' && exit 1)
	echo "$(SUCCESS) kubectl is installed and ready."

check_helm:
	which -s helm || (echo '$(FAILED) Please install helm v3 to use this Helm chart' && exit 1)
	echo "$(SUCCESS) helm is installed and ready."
	
check_git:
	which -s git || (echo '$(FAILED) Please install git to use "make clone/pull"' && exit 1)
	echo "$(SUCCESS) git is installed and ready."

check_docker:
	which -s docker || (echo '$(FAILED) Please install docker to use "make build/push"' && exit 1)
	echo "$(SUCCESS) docker is installed and ready."

check_yarn:
	which -s yarn || (echo '$(FAILED) Please install yarn to use "make rebuild"' && exit 1)
	echo "$(SUCCESS) yarn is installed and ready."

##########################################################
# Helm commands: all, dep, install, uninstall, template  #
#########################################################
all: check_kubectl check_helm $(REALM_IMPORT) dep install

dep: check_helm
	helm dep up

install: check_helm $(REALM_IMPORT)
	if [ ! -d "charts/" ]; then make dep; fi
	if [ "$(REALM_IMPORT)" == "" ]; then helm upgrade --install -n $(NAMESPACE) $(NAME) --create-namespace $(CHART_PATH); fi
	if [ "$(REALM_IMPORT)" != "" ]; then helm upgrade --install -n $(NAMESPACE) $(NAME) --create-namespace $(CHART_PATH) -f values.realmimport.yaml; fi

uninstall: check_helm 
	helm uninstall --wait -n $(NAMESPACE) $(NAME)

template: check_helm
	helm template --debug --dry-run $(NAME) -n $(NAMESPACE) $(CHART_PATH)

dev: check_helm
	helm upgrade --install $(NAME) -n $(NAMESPACE) $(CHART_PATH) -f values.localdev.yaml -f values.localdev.livereload.yaml
	make compile


##########################################################
# Local Dev commands: clone, pull, compile, build, push  #
##########################################################
clone: check_git
	if [ ! -d "src/" ]; then \
	git clone $(APISERVER_REPO) src/apiserver/; \
	git clone $(WEBUI_REPO) src/webui/; \
	fi

pull: clone
	if [ -d "src/" ]; then \
	(cd src/apiserver/ && git pull origin $(APISERVER_UPSTREAM_BRANCH)) \
	(cd src/webui/ && git pull origin $(WEBUI_UPSTREAM_BRANCH)) \
	fi

compile: check_yarn
	(cd src/webui/ && yarn install && yarn build)

build: check_docker clone
	docker build -t $(WEBUI_IMAGE)-dev -f src/webui/Dockerfile.dev src/webui/
	docker build -t $(APISERVER_IMAGE) src/apiserver/
	docker build -t $(WEBUI_IMAGE) src/webui/

push: build
	docker push $(WEBUI_IMAGE)-dev
	docker push $(APISERVER_IMAGE)
	docker push $(WEBUI_IMAGE)


##############################
# kubectl (debug) commands   #
##############################
realm_import: check_kubectl
	kubectl create namespace $(NAMESPACE) >/dev/null 2>&1; \
	kubectl get configmaps keycloak-realm -n $(NAMESPACE) || kubectl create configmap keycloak-realm -n $(NAMESPACE) --from-file=realm.json

acmedns_secret: check_kubectl
	kubectl create namespace $(NAMESPACE) >/dev/null 2>&1; \
	kubectl create secret generic acme-dns -n $(NAMESPACE) --from-file=acmedns.json

status: check_kubectl
	kubectl get pods,pvc -n $(NAMESPACE)

watch: check_kubectl
	kubectl get pods -n $(NAMESPACE) -w

describe: check_kubectl
	kubectl describe pods -n $(NAMESPACE) -lcomponent=$(NAME) $(target)

logs: check_kubectl
	# params: target = proxy,ingress,mongo,apiserver,webui
	# syntax: $(target)
	if [ "$(target)" == "" ]; then echo 'Please specify a target: api (apiserver), ui (webui), proxy (oauth2-proxy), db (mongo, mongodb), kc (keycloak), nginx (ingress)'; echo 'Example usage: "make target=apiserver logs"'; fi
	if [ "$(target)" == "api" -o "$(target)" == "apiserver" ]; then kubectl logs -f -lapp.kubernetes.io/instance=$(NAME),app.kubernetes.io/name=$(NAME) -n $(NAMESPACE) -c apiserver; fi
	if [ "$(target)" == "ui" -o "$(target)" == "webui" ]; then kubectl logs -f -lapp.kubernetes.io/instance=$(NAME),app.kubernetes.io/name=$(NAME) -n $(NAMESPACE) -c webui; fi
	if [ "$(target)" == "db" -o "$(target)" == "mongo" -o "$(target)" == "mongodb" ]; then kubectl logs -f -lapp.kubernetes.io/instance=$(NAME),app.kubernetes.io/name=mongodb; fi
	if [ "$(target)" == "kc" -o "$(target)" == "keycloak" ]; then kubectl logs -f -lapp.kubernetes.io/instance=$(NAME),app.kubernetes.io/name=keycloak -n $(NAMESPACE); fi
	if [ "$(target)" == "nginx" -o "$(target)" == "ingress" ]; then kubectl logs -f -lapp.kubernetes.io/instance=$(NAME),app.kubernetes.io/name=ingress-nginx -n $(NAMESPACE); fi
	if [ "$(target)" == "proxy" -o "$(target)" == "oauth2-proxy" ]; then kubectl logs -f -lapp.kubernetes.io/instance=$(NAME),app.kubernetes.io/name=oauth2-proxy -n $(NAMESPACE); fi

restart: check_kubectl
	kubectl delete pod -n $(NAMESPACE) -lapp.kubernetes.io/name=$(NAME)
     
clean: check_kubectl
	kubectl delete pvc -n $(NAMESPACE) --all

clean_all: check_helm check_kubectl
	make uninstall 2>&1; \
	kubectl delete namespace $(NAMESPACE) --wait --ignore-not-found; \
	kubectl delete validatingwebhookconfigurations $(NAME)-ingress-nginx-admission --ignore-not-found

