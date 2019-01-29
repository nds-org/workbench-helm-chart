Google Kubernetes Engine Deployment
===================================

Deploy Instructions
-------------------

1. Provision an External IP Address in the region that the GKE cluster will be 
deployed and write down the External IP Address that was assigned. 
1. Create DNS hostname for the Workbench and point it the External IP Address. 
    1. Using one of the .googleusercontent.com domains with a self signed SSL cert is 
    impossible due to HTTP Strict Transport Security (HSTS).  
1. Create GKE cluster.
1. Install Helm.
1. Provision nginx-ingress using Helm.
    1. `helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true  --set controller.service.loadBalancerIP=<External IP Address>`
1. Update values.yaml:
    1. Update the domain, subdomain_prefix and support_email as appropriate.
    1. Add `/tmp/` to the start of volume_path and etcd_path as temporary workaround
    until hostPath volumes can be replaced with PersistentVolumeClaims.
    1. The webui and apiserver images should use the develop tag if using Kubernetes 
    version 1.10 or greater.
        1. webui: "ndslabs/angular-ui:develop"
        1. apiserver: "ndslabs/apiserver:develop"  
    1. Add SSL cert/key.
1. Provision Workbench using Helm.
    1. `helm install . --name=workbench --namespace=workbench`


Todo
----

**SMTP**

`dial tcp [::1]:25: getsockopt: connection refused`

https://cloud.google.com/compute/docs/tutorials/sending-mail/

**STORAGE**

```
    "state": {
        "waiting": {
            "reason": "RunContainerError",
            "message": "failed to start container \"xxx\": Error response from daemon: error while creating mount source path '/shared': mkdir /shared: read-only file system"
        }
    },
    "lastState": {
        "terminated": {
            "exitCode": 128,
            "reason": "ContainerCannotRun",
            "message": "error while creating mount source path '/shared': mkdir /shared: read-only file system",
            "containerID": "docker://xxx"
        }

```
