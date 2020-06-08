# ReadWriteMany NFS provisioner


From [Google Container Engine docs](https://cloud.google.com/container-engine/docs/role-based-access-control):

>  Because of the way Container Engine checks permissions when you create a 
> Role or ClusterRole, you must first create a RoleBinding that grants you 
> all of the permissions included in the role you want to create.
> An example workaround is to create a RoleBinding that gives your 
> Google identity a cluster-admin role before attempting to create 
> additional Role or ClusterRole permissions. 


Get your `gcloud` identity:
```
$ gcloud info | grep Account
Account: [myname@example.org]
```

Create  the cluster role binding:
```
kubectl create clusterrolebinding myname-cluster-admin-binding --clusterrole=cluster-admin --user=myname@example.org
```

Create the NFS provisioner (backed by GCE Disk):
```
kubectl create -f deployment.yaml -f rbac.yaml -f class.yaml
```

To test:
```
kubectl create -f test.yaml
kubectl exec busybox1 -c "echo test >> /test/x"
kubectl exec <nfs-provisioner> -- bash -c "cat /export/pvc*/x"
```
