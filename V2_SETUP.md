# Workbench Helm chart

## Getting Started
To install the Helm chart, you can use:
```bash
% make all        # fetch deps + Helm release
# OR 
% make
```

This will use classic Helm commands behind the scenes:
```bash
% helm upgrade --install workbench -n workbench --create-namespace .
```

## Cleanup
To shut down all Workbench dependencies, webui, and apiserver:
```bash
% make uninstall
```

NOTE: this does not shutdown or affect user services

To **delete** all of the associated cluster volumes:
```bash
% make clean
```

NOTE: this will delete your Keycloak Realm and/or MongoDB database and all user data

(OPTIONAL) Last step is to delete the namespace that was created by the `helm install` step:
```bash
% make clean_all
```

NOTE: if you're using cert-manager, backup any necessary secrets to avoid being ratelimited by the LetsEncrypt API



## Configuration

```
TODO: table of values
```

## Dependencies

### MongoDB

To run a local `mongodb` alongside Workbench, you can set `mongodb.enabled` to `true` in the `values.yaml`:
```yaml
mongodb:
  enabled: true
  auth:
    rootUser: workbench
    rootPassword: workbench
  # ... include any other config values from the mongodb chart
```

See https://artifacthub.io/packages/helm/bitnami/mongodb for configuration options

To debug problems with mongodb:
```bash
% make target=mongo logs
```

For more info about MongoDB, see https://www.mongodb.com/docs/manual/tutorial/getting-started/

### Keycloak + PostgreSQL

To run a local `keycloak` alongside Workbench, you can set `keycloak.enabled` to `true` in the `values.yaml`:
```yaml
keycloak:
  enabled: true
  # ... include any other config values from the keycloak chart
```

See https://artifacthub.io/packages/helm/bitnami/keycloak for configuration options

To debug problems with keycloak:
```bash
% make target=keycloak logs
```

For more info about Keycloak, see https://www.keycloak.org/docs/11.0/getting_started/

### OAuth2 Proxy [+ Redis]

To run a local [OAuth2 Proxy](https://artifacthub.io/packages/helm/bitnami/oauth2-proxy) alongside Workbench, you can set `oauth2-proxy.enabled` to `true` in the `values.yaml`:
```yaml
oauth2-proxy:
  enabled: true
  extraArgs:
    - --provider=keycloak-oidc
  # ... include any other config values from the oauth2-proxy chart
```

See https://artifacthub.io/packages/helm/bitnami/oauth2-proxy for configuration options

To debug problems with oauth2-proxy login (403, 500, etc):
```bash
% make target=proxy logs
```

For more info about OAuth2 Proxy, see https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview

For more info about configuring specific providers, see https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/

### ReadWriteMany Volumes (NFS)
You'll need a StorageClass on your cluster that supports ReadWriteMany.

If you already have a volume provisioner running that supports ReadWriteMany, you can skip this section.

#### NFS Client Provisioner: use an existing NFS server to provision RWM volumes

To run a local [NFS Client Provisioner](https://artifacthub.io/packages/helm/supertetelman/nfs-client-provisioner) alongside Workbench, you can set `nfs-client-provisioner.enabled` to `true` in the `values.yaml`:
```yaml
nfs-client-provisioner:
  enabled: true
  # ... include any other config values from the nfs-client-provisioner chart
```

See https://artifacthub.io/packages/helm/supertetelman/nfs-client-provisioner for configuration options

#### NFS Server Provisioner: run your own NFS server to provision RWM volumes

To run a local [NFS Server Provisioner](https://artifacthub.io/packages/helm/kvaps/nfs-server-provisioner) alongside Workbench, you can set `nfs-client-provisioner.enabled` to `true` in the `values.yaml`:
```yaml
nfs-server-provisioner:
  enabled: true
  # ... include any other config values from the nfs-server-provisioner chart
```

See https://artifacthub.io/packages/helm/kvaps/nfs-server-provisioner for configuration options

### Ingress Controller (NGINX)

To run a local [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) alongside Workbench, you can set `ingress-nginx.enabled` to `true` in the `values.yaml`:
```yaml
ingress-nginx:
  enabled: true
  # ... include any other config values from the ingress-nginx chart
```

See https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx for configuration options

To debug problems with nginx (502, 503, 500, etc):
```bash
% make target=nginx logs
```

For more info about NGINX Ingress Controller, see https://kubernetes.github.io/ingress-nginx/deploy/

## Advanced Configuration (Optional)

### Enable TLS with Wildcard DNS certs
1. Install `cert-manager` Helm chart: `jetstack/cert-manager`
2. Add an Issuer that support DNS-01 (see below)
3. Include `tls` section in the top-level `ingress` section of `values.yaml`

#### ACMEDNS
If your provider does not support DNS-01 requests (e.g. Google Domains), you can use ACMEDNS:
1. Register with acmedns for a unique set of credentials: `curl -XPOST https://auth.acme-dns.io/register`
    * This will return a set of credentials as a JSON blob:
```json
{"username":"_username_","password":"_password_","fulldomain":"_id_.auth.acme-dns.io","subdomain":"_id_","allowfrom":[]}
```

2. Build up an `acmedns.json` file using this JSON blob:
    * You'll need to copy and paste this JSON value multiple times to build it up:
```json
{
      "local.ndslabs.org": {"username":"_username_","password":"_password_","fulldomain":"_id_.auth.acme-dns.io","subdomain":"_id_","allowfrom":[]},
      "*.local.ndslabs.org": {"username":"_username_","password":"_password_","fulldomain":"_id_.auth.acme-dns.io","subdomain":"_id_","allowfrom":[]}
}
```
3. Create a secret from the `acmedns.json` file:
```bash
% kubectl create secret -n cert-manager acme-dns --from-file=acmedns.json`
```

### Keycloak Realm Import
Download and import realm.json for a preconfigured `workbench-dev` realm:
```bash
% kubectl create configmap keycloak-realm --from-file=realm.json -n workbench
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

### Map source into running containers (local dev / hostpath only)
Run `make clone` and `make pull` to grab the latest source code.

Use your favorite IDE(s) or local tools use them to import the `src/webui` source code and run `yarn build`.

This will produce a new folder `src/webui/build` containing compiled artifacts that can be mounted directly into the running `webui` container.

Finally, add the following to `values.yaml` and run `make` again:
```yaml
controller:
  extraEnv:
    webui: []
    
    # Enable auto-reload of Python when source changes
    apiserver:
    - name: DEBUG
      value: "true"

  # Mount source code into respective containers
  extraVolumeMounts:
    webui:
    - mountPath: /usr/share/nginx/html/
      name: webuisrc
    apiserver:
    - mountPath: /app/
      name: apisrc

  # Point the extraVolumes at your local machine (hostpath only)
  extraVolumes:
    - name: webuisrc
      hostPath:
        path: /full/path/to/your/workbench-helm-chart/src/webui/build
    - name: apisrc
      hostPath:
        path: /full/path/to/your/workbench-helm-chart/src/apiserver
```

Now you can modify the `webui` or `apiserver` in any way that you see fit, then navigate to https://kubernetes.docker.internal to immediately test your changes.

NOTE: You'll need to re-run `yarn build` after any modifications to the `webui`.

This will trigger the build step (during which you will get a 500 error) that will refresh the files in `src/webui/build`.

## TODO
* source chart somewhere.. NCSA Harbor? github pages?
