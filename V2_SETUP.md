# Workbench Helm chart

## Getting Started
```bash
$ helm upgrade --install workbench -n workbench --create-namespace .
```

## Cleanup
To shut down all Workbench dependencies, webui, and apiserver:
```bash
helm uninstall workbench -n workbench
```

NOTE: this does not shutdown or affect user services

To **delete** all of the associated cluster volumes:
```bash
kubectl delete pvc -n workbench --all
```

NOTE: this will delete your Keycloak Realm and/or MongoDB database and all user data

(OPTIONAL) Last step is to delete the namespace that was created by the `helm install` step:
```bash
kubectl delete namespace workbench
```

NOTE: if you're using cert-manager, backup any necessary secrets to avoid being ratelimited by the LetsEncrypt API



## Configuration

```
TODO: table of values
```

## Dependencies

### MongoDB

See https://artifacthub.io/packages/helm/bitnami/mongodb for configuration options

### Keycloak [+ PostgreSQL]

See https://artifacthub.io/packages/helm/bitnami/keycloak for configuration options

Download and import realm.json for a preconfigured `workbench-dev` realm:
```bash
kubectl create configmap keycloak-realm --from-file=realm.json -n workbench
```

Then add the following to your `values.yaml`:
```yaml
  extraEnvVars:
    - name: KEYCLOAK_EXTRA_ARGS
      value: "-Dkeycloak.import=/config/realm.json"
  extraVolumeMounts:
    - name: config
      mountPath: "/config"
      readOnly: true
  extraVolumes:
    - name: config
      configMap:
        name: keycloak-realm
        items:
        - key: "realm.json"
          path: "realm.json"
```

### OAuth2 Proxy [+ Redis]

To run a local `oauth2-proxy` alongside Workbench, you can set `oauth2-proxy.enabled` to `true` in the `values.yaml`:
```yaml

```

See https://artifacthub.io/packages/helm/oauth2-proxy/oauth2-proxy for configuration options

To debug problems with oauth2-proxy login (403, 500, etc):
```bash
kubectl logs -f deploy/workbench-oauth2-proxy -n workbench
```

### ReadWriteMany Volumes (NFS)

#### NFS Client Provisioner: use an existing NFS server to provision RWM volumes

See https://artifacthub.io/packages/helm/supertetelman/nfs-client-provisioner for configuration options

#### NFS Server Provisioner: run your own NFS server to provision RWM volumes

See https://artifacthub.io/packages/helm/kvaps/nfs-server-provisioner for configuration options

### Ingress Controller (NGINX)

See https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx for configuration options

## Optional: Enable TLS with Wildcard DNS certs
1. Install `cert-manager` Helm chart: `jetstack/cert-manager`
2. Create acme-dns configuration: `acmedns.json`
3. Create secret: `kubectl create secret -n cert-manager acme-dns --from-file=acmedns.json`

## TODO
* source chart somewhere.. NCSA Harbor? github pages?
