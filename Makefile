# Makefile defaults
.PHONY: clone pull build push dep install uninstall status restart clean clean_all
.DEFAULT_GOAL := install


# Workbench Helm chart deployment helper script
#
# To install Workbench:
#   - <modify values.yaml locally>
#   - `make` or `make install` (includes `make dep`)
#
#
# To rebuild images locally:
#   - `make clone`
#   - <modify source locally>
#   - `make push` (includes `make build`) 
#   - `make restart`
#
#
# To uninstall Workbench:
#   - `make uninstall`
#   - `make clean` (WARNING: this will delete all persistent volumes from your namespace)
#   - `make clean_all` (WARNING: this will delete your entire namespace)
#
#
# Dependencies:
#   - `make`
#   - `helm` (+kubeconfig)
#   - `kubectl` (+kubeconfig)
#   - `docker` (optional)
#   - `git` (optional)
#
#


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


#
# Git workflows: clone
#
clone:
	if [ ! -d "src/" ]; then git clone $(APISERVER_REPO) src/apiserver/; git clone $(WEBUI_REPO) src/webui/; fi


#
# Docker workflows: pull, build, push
#
pull:
	docker pull $(APISERVER_IMAGE)
	docker pull $(WEBUI_IMAGE)

build: clone
	docker build -t $(WEBUI_IMAGE) src/webui/
	docker build -t $(APISERVER_IMAGE) src/apiserver/

push: build
	docker push $(APISERVER_IMAGE)
	docker push $(WEBUI_IMAGE)


#
# Helm workflows: dep, install, restart, uninstall
#
dep:
	helm dep up

install: dep
	helm upgrade --install -n $(NAMESPACE) $(NAME) --create-namespace $(CHART_PATH)

uninstall:
	helm uninstall -n $(NAMESPACE) $(NAME)


#
# Kube Debug workflows: restart, clean, clean_all
#
status:
	kubectl get pods -n $(NAMESPACE)

restart:
	kubectl delete pod -n $(NAMESPACE) -lcomponent=$(NAME)
     
clean: uninstall
	kubectl delete pvc -n $(NAMESPACE) --all

clean_all: clean
	kubectl delete namespace $(NAMESPACE)
