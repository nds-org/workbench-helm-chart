# Workbench Helm Chart
A Helm chart for deploying [Labs Workbench](https://github.com/nds-org/ndslabs) on [Kubernetes](https://github.com/kubernetes/kubernetes).

# Prerequisites
You will need the following resources:
* Kubernetes Cluster (either single or multi-node) with `kubectl` and `helm` (v3 or higher) to talk to your cluster
* At least one StorageClass / Volume Provisioner configured in your cluster
* A valid wildcard TLS secret for your desired domain (e.g. `*.mydomain.ndslabs.org`) in your cluster
* The NGINX Ingress controller installed in your cluster (pointed at your default TLS certificate)

For more information on getting these resources set up and configured, see [CLUSTER-SETUP.md](CLUSTER-SETUP.md).

# Configuring the Helm Chart
Clone this repo locally (somewhere with `kubectl` access and the `helm` client installed):
```bash
$ git clone https://github.com/nds-org/workbench-helm-chart && cd workbench-helm-chart/
```

Change the parameters in `values.yaml` (see Configuration Values below):
```bash
$ vi values.yaml
```

NOTES:
* Be sure to set correct values for (at least) your `domain` and `support_email` in `values.yaml`
* If you are using Kubernetes >= 1.8, you will need to enable RBAC in `values.yaml`
* Some environments may allow you to fall back to the default SMTP server (e.g. Nebula, SDSC, etc) if an SMTP configuration is not provided (GMail tends to be the most reliable, and allows for 100 emails per-day)


## Configuration Values
| Key | Description | Type | Default Value |
| -- | -- | -- | -- |


# Deploying the Helm Chart
The following command can be used to deploy the chart to your cluster:
```bash
$ helm upgrade --install workbench . -f values.yaml
```

## Checking Status
You can run `helm list` to view the status of your Helm deployment:
```bash
$ helm list
NAME            	REVISION	UPDATED                 	STATUS  	CHART          	NAMESPACE
workbench		1       	Sat Jun 30 04:39:35 2018	DEPLOYED	workbench-1.1.0	workbench
```

To see the running Pods from your Helm installation:
```bash
$ kubectl get pods
```

# Modifying your Parameters
If you need to change your instance parameters, simply modify `values.yaml` and rerun the deploy command: `helm upgrade --install workbench . -f values.yaml`.

In most cases, this will automatically perform a rolling upgrade on any chart resources that have changed.

If you want to be sure that the Pod that is running has the newest configuration from the chart, you can always `kubectl get pod` to get the pod name and `kubectl delete pod <POD NAME>` to kill the Pod. A new Pod will automatically be recreated when the first is killed.

# Shutting it Down
To clean up all resources used by Labs Workbench, simply run `helm uninstall workbench`

NOTE: This does not currently clean up or delete any user namespaces or applications launched by those users.

# TODO
* Improve hosting/workflow - user should not have to clone this repo to install via Helm
* OAuth vs custom auth option?
* API server nodeSelector for running user workload as an option?
* Support more options for SMTP?
* Verbose documentation for configuration options
