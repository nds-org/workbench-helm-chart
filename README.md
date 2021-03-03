# workbench-helm-chart
A Helm chart for deploying [Labs Workbench](https://github.com/nds-org/ndslabs) on [Kubernetes](https://github.com/kubernetes/kubernetes).

# Prerequisites
You will need the following resources:
* Kubernetes Cluster (either single or multi-node) with `kubectl` and `helm` (v3) to talk to your cluster
* At least one Ingress controller installed in your cluster (preferrably NGINX Ingress controller)
* At least one StorageClass / Volume Provisioner configured in your cluster
* A valid wildcard TLS certificate for your desired domain (e.g. `*.mydomain.ndslabs.org`)

For more information on getting these resources set up and configured, see [CLUSTER-SETUP.md].

# Configuring the Helm Chart
Clone this repo locally (somewhere with `kubectl` access and the `helm` client installed):
```bash
$ git clone https://github.com/nds-org/workbench-helm-chart && cd workbench-helm-chart/
```

Tweak the parameters in `values.yaml`:
```bash
vi values.yaml
```

* NOTE 1: Be sure to set correct values for your `domain` and `support_email` in `values.yaml`.
* NOTE 2: If you are using Kubernetes >= 1.8, you will need to enable RBAC in `values.yaml`.
* NOTE 3: Some environments may allow you to fall back to the default SMTP server (e.g. Nebula, SDSC, etc) if an SMTP configuration is not provided. (GMail tends to be the most reliable, and allows for 100 emails per-day)

Deploy the helm chart:
```bash
ubuntu@lambert8-dev:~/workbench-helm-chart$ helm install . --name=workbench --namespace=workbench
NAME:   workbench
LAST DEPLOYED: Fri Jun 29 23:48:48 2018
NAMESPACE: workbench
STATUS: DEPLOYED

RESOURCES:
==> v1/Pod(related)
NAME                                READY  STATUS             RESTARTS  AGE
ndslabs-workbench-5b8669648b-ndld6  0/4    ContainerCreating  0         0s

==> v1/Namespace
NAME       STATUS  AGE
workbench  Active  0s

==> v1/Secret
NAME                TYPE    DATA  AGE
ndslabs-tls-secret  Opaque  2     0s

==> v1/ConfigMap
NAME               DATA  AGE
ndslabs-workbench  24    0s

==> v1/ServiceAccount
NAME               SECRETS  AGE
ndslabs-workbench  1        0s

==> v1/ClusterRole
NAME               AGE
ndslabs-workbench  10m

==> v1/ClusterRoleBinding
NAME               AGE
ndslabs-workbench  10m

==> v1/Service
NAME               TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)                  AGE
ndslabs-workbench  ClusterIP  10.109.18.61  <none>       80/TCP,30001/TCP,25/TCP  0s

==> v1beta1/Deployment
NAME               DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
ndslabs-workbench  1        1        1           0          0s

==> v1beta1/Ingress
NAME                    HOSTS                  ADDRESS  PORTS  AGE
ndslabs-workbench-auth  www.mldev.ndslabs.org  80, 443  0s
ndslabs-workbench-open  www.mldev.ndslabs.org  80, 443  0s
```

You should see output like that above indicating that Labs Workbench is starting up.

# Checking Status
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
If you need to change your instance parameters, simply modify `values.yaml` and run `helm upgrade <release-name> .`

The `<release-name>` can be discovered using the `helm list` command, shown above. You can override this by passing `--name=<release-name>` to `helm install`

This will perform a rolling upgrade on your chart's resources to use the newest values.

# Shutting it Down
To clean up all resources used by Labs Workbench, simply run `helm delete <release-name>`

The `<release-name>` can be discovered using the `helm list` command, shown above. You can override this by passing `--name=<release-name>` to `helm install`

This will tear down and remove all resources installed by this Helm chart:
```bash
ubuntu@lambert8-dev:~/workbench-helm-chart$ helm delete workbench
release "workbench" deleted
```

NOTE: This does not currently clean up or delete any user namespace or deployments.

# TODO
* Does nginx-ingress need special config for `default-ssl-cert`?
* Improve hosting/workflow - user should not have to clone this repo to install via Helm
* NFS / PVC vs hostPath option?
* OAuth vs custom auth option?
* Ingress Controller vs NodePort option?
* API server nodeSelector for running user workload as an option?
* Support more options for SMTP?
* Verbose documentation for configuration options
