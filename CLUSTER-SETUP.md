# Workbench Helm Chart: Kubernetes Cluster Setup
You will need the following resources:
* Kubernetes Cluster (either single or multi-node) with `kubectl` and `helm` (v3) to talk to your cluster
* At least one StorageClass / Volume Provisioner configured in your cluster
* A valid wildcard TLS secret for your desired domain (e.g. `*.mydomain.ndslabs.org`) in your cluster
* The NGINX Ingress controller installed in your cluster (pointed at your default TLS certificate)

## Setup: Kubernetes Cluster
You will need a Kubernetes Cluster (either single or multi-node) with `kubectl` and `helm` (v3) to talk to the cluster.

### Running locally (developer only)
Several options exist for running a Kubernetes cluster locally:
* Kubernetes under Docker for MacOSX/Windows - you can enable Kubernetes in the Settings and install the `helm` client
* `minikube` - you will need to set up a custom domain pointing to your `minikube ip`

### Remote VM Single-node
For a short 3-step process for setting this up on a remote VM (where `minikube` may be unavailable), check out [our fork of Data8's kubeadm-bootstrap](https://github.com/nds-org/kubeadm-bootstrap)
This will install Kubernetes via `kubeadm` and configure it to run as a single node cluster. It will also deploy the NGINX Ingress controller to the cluster, allowing you to skip the steps for deploying it manually (provided below).

### Remote VM Multi-node
For a more robust Workbench cluster the spans multiple OpenStack VMs, you can use our [kubeadm-terraform](https://github.com/nds-org/kubeadm-terraform) plan to spin up a cluster of your desired size and scale. 

## StorageClass / Volume Provisioner
At least one StorageClass needs to be configured in your cluster as the default.
GKE and AWS EKS will provide these by default, but OpenStack does not offer the same out of the box.
If you have already chosen and configured a StorageClass that can privision PersistentVolume (PVs) for you, then you can skip this step.

To check the StorageClasses in your cluster:
```bash
$ kubectl get storageclass
NAME                 PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
hostpath (default)   docker.io/hostpath   Delete          Immediate           false                  32d
```

If you don't see any listed with `(default)`, you'll need to set one as the default by following [these steps](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/).

If you do not see *any* StorageClass listed, then you'll need to set one up first (see below).

### Setup: NFS Server Provisioner

While there are many volume provisioners available, we tend to use the [NFS Server Provisioner](https://github.com/nds-org/kubeadm-terraform/tree/develop/assets/nfs) to provision volumes for Workbench.

To use the NFS Server Provisioner in your cluster, run the following command:
```bash
$ kubectl apply -f https://github.com/nds-org/kubeadm-terraform/tree/develop/assets/nfs
```

This will also create an empty test PersistentVolumeClaim (PVC) in your cluster. Once the NFS server comes online, the provisioner will create a PV for any PVCs that are requested. Once provisioned, `kubectl get pvc` should tell you that the `STATUS` of the PVC will change to `Bound`.


## Wildcard TLS Secret
You will need a valid wildcard TLS certificate for your chosen Workbench domain. If you have already created a valid wildcard TLS secret, skip this step.

If you already have valid certificate and private key files for your wildcard domain, then you can create a secret from them using the following command:
```bash
kubectl create secret tls --namespace=default ndslabs-tls \
  --cert=path/to/cert/file \
  --key=path/to/key/file
```

Once you have the secret, you will need to tell NGINX to use that as the default TLS certificate (see below).


### (optional) Automatic Certificate Renewal via LetsEncrypt

You can also configure [`cert-manager`](https://cert-manager.io/docs/installation/kubernetes/) to automatically renew your wildcard certs using a [DNS-01 challenge](https://cert-manager.io/docs/configuration/acme/dns01/).

NOTE: If your DNS provider does not allow for programmatic DNS updates (e.g. Google Domains), then you can register with [ACMEDNS](https://cert-manager.io/docs/configuration/acme/dns01/acme-dns/) and use it to resolve DNS-01 challenges for you.

## NGINX Ingress Controller
* At least one Ingress controller installed in your cluster (preferrably NGINX Ingress controller)

To deploy the NGINX Ingress controller, use the following commands:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress ingress-nginx/ingress-nginx -n kube-system --set controller.hostPort.enabled=true --set controller.kind=Deployment --set controller.extraArgs.default-ssl-certificate=default/ndslabs-tls
```

Finally, you will need to point the NGINX Ingress controller at this secret to use it across multiple namespaces:
```bash
  helm upgrade <RELEASE_NAME> --namespace <RELEASE_NAMESPACE> --reuse-values --set controller.extraArgs.default-ssl-certificate=default/ndslabs-tls
```


# All Done!
With all of the above in place, you should be ready to deploy the Workbench Helm chart to your cluster.
