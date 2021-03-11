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

You can run `helm list` to see the Helm charts that you have deployed to the cluster:
```bash
$ helm list
NAME                    REVISION        UPDATED                         STATUS          CHART           NAMESPACE
workbench               1               Sat Jun 30 04:39:35 2018        DEPLOYED        workbench-1.1.0 workbench
```

To see the Pods from your Helm installation, you can use `kubectl get pods`:
```bash
$ kubectl get pods -l component=workbench
NAME                         READY   STATUS    RESTARTS   AGE
workbench-7459f9ccd7-85dwh   4/4     Running   3          19m
```

Once all of the Pods are `Running`, you should be able to access the Workbench UI by navigating your browser to the domain you've configured in `values.yaml` (e.g. https://www.local.ndslabs.org)

## Register a Test User
Once the Workbench Pod is `Running`, the following commands can be used to quickly create a `demo` user and allow you to interact with the system.
```bash
# Print out the password for the "admin" user - NOTE: this changes every time the Pod restarts
$ kubectl exec -it deploy/workbench -c apiserver -- cat password.txt
aunLc3n6TaVrTixTq4HSo5OkrgcTO9

$ kubectl exec -it deploy/workbench -c apiserver -- /ndslabsctl/ndslabsctl-linux-amd64 login admin
Password: <copy and paste password from above>
Login succeeded

$ kubectl exec -it deploy/workbench -c apiserver -- /ndslabsctl/ndslabsctl-linux-amd64 add account -f /templates/demo-account.json
Added account demo
```

You should now be able to log into the Workebnch UI as the `demo` user with a password of `demo123`.

NOTE: The `demo` user's default password is insecure, and should be changed if you plan to use this account on a production system.

## Debugging Steps
You can run `helm list` to view the status of your Helm deployment:
```bash
$ helm list
NAME            	REVISION	UPDATED                 	STATUS  	CHART          	NAMESPACE
workbench		1       	Sat Jun 30 04:39:35 2018	DEPLOYED	workbench-1.1.0	workbench
```

To see the running Pods from your Helm installation:
```bash
$ kubectl get pods -l component=workbench
NAME                         READY   STATUS    RESTARTS   AGE
workbench-7459f9ccd7-85dwh   4/4     Running   3          19m
```

### Check Workbench Pod Status
If the Pod Status is `Pending` or `ContainerCreating`, then the containers in the Pod have not yet been created. You can still use `kubectl describe pod -l component=workbench` to view events associated with creation of these containers:
```bash
$ kubectl describe pod -l component=workbench
Name:         workbench-7459f9ccd7-85dwh
Namespace:    default
Priority:     0
Node:         docker-desktop/192.168.65.3
Start Time:   Thu, 11 Mar 2021 11:09:18 -0600
Labels:       component=workbench
              pod-template-hash=7459f9ccd7
Annotations:  configHash: 2555b2033eb9006edabefb2fc5eab217f1b9d8496cc746951ed091cd4ec8f038
Status:       Running
IP:           10.1.4.58
IPs:
  IP:           10.1.4.58
Controlled By:  ReplicaSet/workbench-7459f9ccd7
Containers:
  webui:
    . . .
  apiserver:
    . . .
  etcd:
    . . .
  smtp:
    . . .
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  22m                default-scheduler  Successfully assigned default/workbench-7459f9ccd7-85dwh to docker-desktop
  Normal   Pulling    22m                kubelet            Pulling image "ndslabs/angular-ui:develop"
  Normal   Pulled     21m                kubelet            Successfully pulled image "ndslabs/angular-ui:develop" in 1m4.9393197s
  Normal   Created    21m                kubelet            Created container webui
  Normal   Started    21m                kubelet            Started container webui
  Normal   Pulled     21m                kubelet            Successfully pulled image "ndslabs/apiserver:develop" in 1.1320863s
  Normal   Pulling    21m                kubelet            Pulling image "namshi/smtp:latest"
  Normal   Started    21m                kubelet            Started container etcd
  Normal   Created    21m                kubelet            Created container etcd
  Normal   Pulled     21m                kubelet            Container image "quay.io/coreos/etcd:v3.3" already present on machine
  Normal   Pulled     21m                kubelet            Successfully pulled image "namshi/smtp:latest" in 829.0759ms
  Normal   Created    21m                kubelet            Created container smtp
  Normal   Started    21m                kubelet            Started container smtp
  Normal   Pulled     21m                kubelet            Successfully pulled image "ndslabs/apiserver:develop" in 834.3305ms
  Warning  BackOff    21m (x2 over 21m)  kubelet            Back-off restarting failed container
  Normal   Pulling    21m (x3 over 21m)  kubelet            Pulling image "ndslabs/apiserver:develop"
  Normal   Started    21m (x3 over 21m)  kubelet            Started container apiserver
  Normal   Created    21m (x3 over 21m)  kubelet            Created container apiserver
  Normal   Pulled     21m                kubelet            Successfully pulled image "ndslabs/apiserver:develop" in 828.5744ms
```

If the Pod Status is `Pending`, there is likely a problem with your Volume Provisioner configuration. Make sure that the `workbench-etcd` PVC was created and that its Status is `Bound`:
```bash
$ kubectl get pvc
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
workbench-etcd   Bound    pvc-bb02201d-29bc-4beb-acbf-7752edab22f2   1Gi        RWO            hostpath       26m
```

If the Pod Status is `Error` or `CrashLoopBackoff`, then the container has started but has encoutnered an error. You will need to view the container logs for the `apiserver` and/or `webui` to determine the source of the problem:
```bash
$ kubectl logs -f deploy/workbench -c apiserver
Cloning into '/specs'...
Cloned master https://github.com/nds-org/ndslabs-specs.git
I0311 17:11:22.414361      24 server.go:128] Connecting to etcd on localhost:4001
I0311 17:11:22.417573      24 server.go:134] Connected to etcd
I0311 17:11:22.418006      24 server.go:138] File /root/.kube/config does not exist, assuming in-cluster
I0311 17:11:22.455811      24 server.go:162] Connected to Kubernetes
I0311 17:11:22.455892      24 server.go:186] Checking for TLS issuer...
I0311 17:11:22.456029      24 server.go:188] Using TLS cluster issuer: acmedns-issuer
I0311 17:11:22.456091      24 server.go:208] Starting Workbench API server (1.2.0  2021-03-11 16:55)
I0311 17:11:22.456123      24 server.go:209] Using etcd localhost:4001 
I0311 17:11:22.456175      24 server.go:210] Using kube-apiserver https://10.96.0.1:443
I0311 17:11:22.456196      24 server.go:211] Using home pvc suffix -home
I0311 17:11:22.456321      24 server.go:212] Using specs dir /specs
I0311 17:11:22.456360      24 server.go:213] Using nodeSelector : 
I0311 17:11:22.456446      24 server.go:214] Listening on port 30001
I0311 17:11:22.456480      24 server.go:220] prefix /api/
I0311 17:11:22.456543      24 server.go:223] CORS origin https://www.local.ndslabs.org
I0311 17:11:22.456573      24 server.go:244] session timeout 30m0s
I0311 17:11:22.456631      24 server.go:246] domain local.ndslabs.org
I0311 17:11:22.456666      24 server.go:247] ingress LoadBalancer
I0311 17:11:22.457343      24 server.go:385] Loading service specs from /specs
I0311 17:11:22.779581      24 server.go:406] Listening on 30001
I0311 17:11:22.779696      24 server.go:413] Admin server listening on 30002


$ kubectl logs -f deploy/workbench -c webui
2021-03-11T17:10:26.636Z - info: Workbench Login API listening on port 3000
2021-03-11T17:10:26.643Z - info: Connecting to Workbench API server at http://localhost:30001/api
```

### Check VM Firewall / IP Tables / Port Forwarding
If all Pods are Running and you are still unable to access the Workbench UI, try navigating directly to your public IP - this should return a generic 404 error page that says NGINX on it. If you do not see this error page, then you may need to open ports 80 and 443 on your VM.

If you have confirmed that these ports are open and are still not seeing the 404 error, make sure that the Ingress Controller chart was deployed with `controller.hostPort.enabled=true` and that the Pod is `Running`:
```bash
$ helm list -A
NAME        	NAMESPACE   	REVISION	UPDATED                             	STATUS  	CHART               	APP VERSION
cert-manager	cert-manager	1       	2021-01-29 16:46:11.809016 -0600 CST	deployed	cert-manager-v1.0.1 	v1.0.1     
ingress     	kube-system 	1       	2021-02-04 12:36:56.312356 -0600 CST	deployed	ingress-nginx-3.23.0	0.44.0     
oauth2-proxy	default     	210     	2021-03-08 13:27:07.79816 -0600 CST 	deployed	oauth2-proxy-3.2.5  	5.1.0      
workbench   	default     	117     	2021-03-08 13:36:03.744636 -0600 CST	deployed	workbench-1.1.0     	1.0    

$ helm get values ingress -n kube-system
USER-SUPPLIED VALUES:
controller:
  hostPort:
    enabled: true
  kind: Deployment

$ kubectl get deploy -n kube-system
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
coredns                            2/2     2            2           40d
ingress-ingress-nginx-controller   1/1     1            1           34d
```

If the NGINX Ingress Controller Pod is `Pending`, then something else may be using ports 80 and/or 443. You will need to either shut down that service or choose a different port.

### Check NGINX Ingress Controller Pod Status / logs
If you correctly see the 404 error when navigating directly to the VM's IP but are still unable to see the Workbench UI, there may be a TLS error. You can examine the NGINX Ingress Controller logs to see more details about errors in the `tls` configuration of Ingress resources.

We can check the logs of the NGINX Ingress Controller using `kubectl logs`.

If your TLS configuration is valid and accepted, then you should see the following messages come through (one for each set of ingress rules created by Workbench):
```bash
$ kubectl logs -f ingress-ingress-nginx-controller-bdb9cf57b-h4zlb -n kube-system
I0311 17:57:23.489437       7 main.go:112] "successfully validated configuration, accepting" ingress="workbench-auth/default"
I0311 17:57:23.512922       7 event.go:282] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"workbench-auth", UID:"327c9e8d-4979-4120-bf1e-9df1381804e6", APIVersion:"networking.k8s.io/v1beta1", ResourceVersion:"5084623", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0311 17:57:23.760615       7 main.go:112] "successfully validated configuration, accepting" ingress="workbench-open/default"
I0311 17:57:23.772658       7 event.go:282] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"workbench-open", UID:"c5b84e36-7781-4b49-9839-98c1403687a9", APIVersion:"networking.k8s.io/v1beta1", ResourceVersion:"5084626", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0311 17:57:24.072428       7 main.go:112] "successfully validated configuration, accepting" ingress="workbench-root/default"
I0311 17:57:24.094212       7 event.go:282] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"default", Name:"workbench-root", UID:"65b1ace3-a005-4d4f-886f-05aeb8e4e1cf", APIVersion:"networking.k8s.io/v1beta1", ResourceVersion:"5084628", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
```

Using your browser, check to see if the TLS certificate is valid. In Google Chrome, this can be done by clicking the padlock icon to the left of the address bar and choosing Certificate. If the Certificate is `Invalid`, check that the Issuer is correct:
* For valid/production LetsEncrypt cert, this will likely appear as `R3` for a real certificate
* If you see something like `Fake LE Intermediate`, then you are likely using the LetsEncrypt staging issuer (for `cert-manager`) and will need to issue a production cert instead
* If you see something like `Fake Ingress Controller`, then the Ingress controller may have rejected your TLS secret and is using its own instead

# Modifying your Parameters
If you need to change your instance parameters, simply modify `values.yaml` and rerun the same command you used to deploy:
```bash
$ helm upgrade --install workbench . -f values.yaml
```

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
