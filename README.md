# workbench-helm-chart
A Helm chart for deploying [Labs Workbench](https://github.com/nds-org/ndslabs) on [Kubernetes](https://github.com/kubernetes/kubernetes).

# Prerequisites
* Kubernetes Cluster (either single or multi-node)
* `kubectl` configured to talk to your cluster
* Helm/Tiller installed in your cluster
* Helm client available locally

For an extremely simple 3-step process for getting all of the above set-up, check out [Data8's kubeadm-bootstrap](https://github.com/data-8/kubeadm-bootstrap)

# Usage
Clone this repo locally (somewhere with `kubectl` access and the `helm` client installed):
```bash
ubuntu@lambert8-dev:~$ git clone https://github.com/nds-org/workbench-helm-chart && cd workbench-helm-chart/
```

Generate a self-signed certificate:
```bash
ubuntu@lambert8-dev:~/workbench-helm-chart$ ./generate-self-signed-cert.sh example.com

Generating self-signed certificate for example.com
Generating a 2048 bit RSA private key
........................................................................................................................................+++
........+++
writing new private key to 'certs/example.com.key'
-----
```

Tweak the parameters in `values.yaml`:
```bash
vi values.yaml
```

* NOTE 1: Be sure to set correct values for your `domain` and `support_email` in `values.yaml`.
* NOTE 2: Be sure to copy and paste the contents of your self-signed cert/key into the appropriate variables in `values.yaml`.
* NOTE 3: If you are using Kubernetes >= 1.8, you will likely need to enable RBAC in `values.yaml`.
* NOTE 4: If you do not specify an SMTP configurations, some environments may allow you to fall back to the default SMTP server (e.g. Nebula, SDSC, etc).

Deploy the helm chart:
```bash
ubuntu@lambert8-dev:~/workbench-helm-chart$ helm install .
NAME:   joking-greyhound
LAST DEPLOYED: Fri Jun 29 23:48:48 2018
NAMESPACE: default
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
ubuntu@lambert8-dev:~/workbench-helm-chart$ helm list
NAME            	REVISION	UPDATED                 	STATUS  	CHART          	NAMESPACE
joking-greyhound	1       	Sat Jun 30 04:39:35 2018	DEPLOYED	workbench-1.1.0	default  
support         	1       	Fri Jun 29 22:29:34 2018	DEPLOYED	support-0.1.0  	support  
```

# Modifying your Parameters
If you need to change your instance parameters, simply modify `values.yaml` and run `helm upgrade <release-name> .`

The `<release-name>` can be discovered using the `helm list` command, shown above.

This will perform a rolling upgrade on your chart's resources to use the newest values:
```bash
ubuntu@lambert8-dev:~/workbench-helm-chart$ helm upgrade joking-greyhound .
Release "joking-greyhound" has been upgraded. Happy Helming!
LAST DEPLOYED: Sat Jun 30 04:39:35 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Namespace
NAME       STATUS  AGE
workbench  Active  4h

==> v1beta1/Deployment
NAME               DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
ndslabs-workbench  1        0        0           0          4h

==> v1beta1/Ingress
NAME                    HOSTS                  ADDRESS  PORTS  AGE
ndslabs-workbench-open  www.mldev.ndslabs.org  80, 443  4h
ndslabs-workbench-auth  www.mldev.ndslabs.org  80, 443  4h

==> v1/Secret
NAME                TYPE    DATA  AGE
ndslabs-tls-secret  Opaque  2     4h

==> v1/ConfigMap
NAME               DATA  AGE
ndslabs-workbench  24    4h

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
ndslabs-workbench  ClusterIP  10.109.18.61  <none>       80/TCP,30001/TCP,25/TCP  4h


```

# Shutting it Down
To clean up all resources used by Labs Workbench, simply run `helm delete <release-name>`

The `<release-name>` can be discovered using the `helm list` command, shown above.

This will tear down and remove all resources installed by this Helm chart:
```bash
ubuntu@lambert8-dev:~/workbench-helm-chart$ helm delete joking-greyhound
release "joking-greyhound" deleted
```

NOTE: This does not currently clean up or delete any user namespace or deployments.

# TODO
* NFS / PVC vs hostPath option?
* OAuth vs custom auth option?
* Ingress Controller vs NodePort option?
* API server nodeSelector for running user workload as an option?
* Figure out how to correctly set the namespace listed by `helm list` (it always says "default" for some reason)
* Support more options for SMTP?
