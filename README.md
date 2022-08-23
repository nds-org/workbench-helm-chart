# Workbench Helm chart
[NDS Labs Workbench](http://www.nationaldataservice.org/platform/workbench.html) is an open-source platform for hosting and launching pre-packages apps for educational or workshop environments.

## TL;DR
```bash
% helm dep up
% helm upgrade --install workbench -n workbench --create-namespace .
```

## Introduction
This chart bootstraps a Workbench [webui](https://github.com/nds-org/workbench-webui) and [apiserver](https://github.com/nds-org/workbench-apiserver-python) on a [Kubernetes](http://kubernetes.io/) cluster using the [Helm](https://helm.sh/) package manager.

## Prerequisites
* Running: Kubernetes 1.22+
* Installed: `kubectl` + `helm` v3 (required)
* Installed: `docker` + `git` (optional, for local docker builds)
* Installed: `yarn` (optional, for local dev/compilation)

## Installing the Chart
Download dependency subcharts and install a new Helm release:
```bash
% helm dep up
% helm upgrade --install workbench -n workbench --create-namespace .
```

You can also use the included Makefile helper:
```bash
% make all        # fetch deps + Helm release
# OR 
% make
```

## Uninstalling the Chart
To shut down all Workbench dependencies, webui, and apiserver:
```shell
% helm uninstall workbench -n workbench
```

NOTE: this does not shutdown or affect UserApps

You can also use the included Makefile helper:
```bash
% make uninstall
```

## Configuration
The following table lists the configurable parameters of the Workbench chart and their default values.

### Controller
These options affect the Deployment resource created by this chart.

| Path | Type | Description | Default |
| ---- | ---- | ----------- | ------- |
| `controller.kind` | string | Kind to use for application manifest | `Deployment` |
| `controller.images.webui` | string | Image to use for `webui` container | `ndslabs/webui:react` |
| `controller.images.apiserver` | string | Image to use for `apiserver` container | `ndslabs/webui:react` |
| `controller.initContainers` | array[map] | Specify `initContainers` for main application | `[]` |
| `controller.extraEnv.webui` | array[map] | Additional `env` to set for `webui` container | `[]` |
| `controller.extraEnv.apiserver` | array[map] | Additional `env` variables to set for `apiserver` container | `[]` |
| `controller.extraVolumeMounts.webui` | array[map] | Additional `volumeMounts` to set for `webui` container | `[]` |
| `controller.extraVolumeMounts.apiserver` | array[map] | Additional `volumeMounts` to set for `apiserver` container | `[]` |
| `controller.extraVolumes` | array[map] | Additional `volumes` to attach to the main application | `[]` |

### Ingress
These options affect the Ingress resources created by this chart.

| Path | Type | Description | Default |
| ---- | ---- | ----------- | ------- |
| `ingress.class` | string | Class name for Ingress resources | `""` |
| `ingress.tls` | array[map] | TLS config to set for Ingress resources | `[]` |
| `ingress.tls.hosts` | array[string] | Host names to set for TLS on Ingress resource | `[]` |
| `ingress.api.annotations` | map | Annotations to set for `api` Ingress resources | `{}` |
| `ingress.webui.annotations` | map | Annotations to set for `webui` Ingress resources | `{}` |

### Workbench Options
These options affect the internals of Workbench and the customization of the WebUI.

| Path | Type | Description | Default |
| ---- | ---- | ----------- | ------- |
| `config.frontend.signin_url` | string | URL to route frontend requests to "Log In"  | `https://kubernetes.docker.internal/oauth2/start?rd=https%3A%2F%2Fkubernetes.docker.internal%2F` |
| `config.frontend.customization.product_name` | string | Human-friendly name to use for this product in the navbar | `Workbench` |
| `config.frontend.customization.landing_html` | string | HTML string to use as the splash text on the Landing Page | existing HTML |
| `config.frontend.customization.favicon_path` | string | Image to use as the favicon | `/favicon.svg` |
| `config.frontend.customization.brand_logo_path` | string | Image to use as the brand log (top-left of navbar) | `/favicon.svg` |
| `config.frontend.customization.learn_more_url` | string | (currently unused) URL to use for the "Learn More" button on the Landing Page | `http://www.nationaldataservice.org/platform/workbench.html` |
| `config.frontend.customization.help_links` | array | List of links to use in the navbar "Help" section | existing URLs |
| `config.backend.mongo.uri` | string | URI pointing at running MongoDB instance | `mongodb://workbench-mongodb.workbench.svc.cluster.local:27017/ndslabs` |
| `config.backend.mongo.db` | string | Database name to use in MongoDB | `ndslabs` |
| `config.backend.mongo.keycloak.hostname` | string | URI pointing at running Keycloak instance | `https://kubernetes.docker.internal/auth` |
| `config.backend.keycloak.realmName` | string | Realm name to use in Keycloak | `workbench-dev` |
| `config.backend.keycloak.clientId` | string | OIDC ClientID to use for Keycloak auth | `workbench-local` |
| `config.backend.keycloak.clientSecret` | string | OIDC ClientSecret to use for Keycloak auth | `""` |
| `config.backend.domain` | string | Domain name (used by backend for self-reference) | `kubernetes.docker.internal` |
| `config.backend.insecure_ssl_verify` | string | If `false`, skip checking insecure/invalid TLS certificates | `true` |
| `config.backend.storage.home.storage_class` | string | StorageClass to use for user Home volumes | `nfs` |
| `config.backend.storage.home.claim_suffix` | string | Suffix to append to names of user Home volumes | `-home` |
| `config.backend.storage.shared.enabled` | bool | If true, mount a Shared volume to each UserApp | `false` |
| `config.backend.storage.shared.volume_path` | string | Path within the container to mount the Shared volume | `/tmp/shared` |
| `config.backend.storage.shared.read_only` | bool | If true, mount the Shared volume as ReadOnly | `true` |

### Misc
Other miscellaneous top-level configuration options.

| Path | Type | Description | Default |
| ---- | ---- | ----------- | ------- |
| `extraDeploy` | array | List of additional resources to create | `[]` |
| `tolerations` | array | List of tolerations to include | `[]` |
| `resources.api` | map | Resources to apply to `api` container | `{}` |
| `resources.webui` | map | Resources to apply to `webui` container | `{}` |
| `nodeSelector` | map | Node selector(s) to apply to `webui` container | `{}` |
| `affinity` | map | Affinity to apply to `webui` container | `{}` |


### Currently Unused?
These options are currently present, but may not yet be used.

| Path | Type | Description | Default |
| ---- | ---- | ----------- | ------- |
| `config.backend.timeout` | int | (currently unused) startup timeout for UserApps | `30` |
| `config.backend.inactivity_timeout` | int | (currently unused) Shut down inactive services after this many minutes | `480` |
| `config.backend.specs.repo` | string | (currently unused) Git repo from which to pull application specs | `https://github.com/nds-org/ndslabs-specs.git` |
| `config.backend.specs.branch` | string | (currently unused) Git branch from which to pull application specs | `master` |
| `config.backend.storage.shared.storage_class` | string | (currently unused) StorageClass used to create the Shared volume | `nfs` |
| `ingress.userapps.annotations` | map | Annotations to set for Ingress resources of created UserApps | `{}` |


## Subcharts
* [MongoDB](https://artifacthub.io/packages/helm/bitnami/mongodb)
* [Keycloak](https://artifacthub.io/packages/helm/bitnami/keycloak)
* [OAuth2 Proxy](https://artifacthub.io/packages/helm/bitnami/oauth2-proxy)
* [NFS Client Provisioner](https://artifacthub.io/packages/helm/supertetelman/nfs-client-provisioner)
* [NFS Server Provisioner](https://artifacthub.io/packages/helm/kvaps/nfs-server-provisioner)
* [NGINX Ingress Controller](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx)

### MongoDB

To run a local `mongodb` alongside Workbench, you can set `mongodb.enabled` to `true` in the `values.yaml`:
```yaml
mongodb:
  enabled: true
  # ... include any other config values from the mongodb chart
  auth:
    rootUser: workbench
    rootPassword: workbench
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
  httpRelativePath: "/auth/"
  auth:
     adminUser: "admin"
     adminPassword: "workbench"
  proxyAddressForwarding: true
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
  # ... include any other config values from the oauth2-proxy chart
  extraArgs:
    - --provider=keycloak-oidc
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

NOTE: You should only need the client OR the server, but you do not need both running.

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
  controller:
    kind: Deployment
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
2. Add an Issuer that support DNS-01 (see below):
```yaml
apiVersion: cert-manager.io/v1
kind: Issuer 
metadata:
  name: letsencrypt-staging
  namespace: workbench
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: email@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the DNS-01 challenge provider
    solvers:
    - dns01:
        # ...
```
3. Include `tls` section in the top-level `ingress` section of `values.yaml`:
```yaml
ingress:
  class: "nginx"
  tls:
    - hosts:
      - "local.ndslabs.org"
      - "*.local.ndslabs.org"
```

WARNING: Do not include the same `issuer` or `cluster-issuer` annotation on multiple ingress rules.

WARNING: LetsEncrypt will [rate limit](https://letsencrypt.org/docs/rate-limits/) you if you request too many certs are requested for the same domain.

To avoid this, use the [staging environment](https://community.letsencrypt.org/t/staging-endpoint-for-acme-v2/49605) (as above) for testing.

When you are ready (after testing) to move from [staging](https://letsencrypt.org/docs/staging-environment/) to real certs, you can use the [production environment](https://community.letsencrypt.org/t/acme-v2-production-environment-wildcards/55578).


#### DNS-01 via ACMEDNS
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

4. Point an Issuer at the `acme-dns` secret:
```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
  namespace: workbench
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: email@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - dns01:
        acmeDNS:
          host: https://auth.acme-dns.io
          accountSecretRef:
            name: acme-dns
            key: acmedns.json 
```

5. Add the issuer annotation to your `ingress.api.annotations` section:
```yaml
ingress:
  class: "nginx"
  tls:
    # ....
  api:
    annotations:
      cert-manager.io/issuer: "acmedns-staging"
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/force-ssl-redirect: "true"
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

## Cleaning Up
To **delete** all of the associated cluster volumes:
```bash
% kubectl delete pvc --all -n workbench
```

```bash
% make clean
```

NOTE: this will delete your Keycloak Realm and/or MongoDB database and all user data

(OPTIONAL) Last step is to delete the namespace that was created by the `helm install` step:
```bash
% kubectl delete namespace workbench
```

You can also use the included Makefile helper:
```bash
% make clean_all
```

NOTE: if you're using cert-manager, backup any necessary secrets to avoid being ratelimited by the LetsEncrypt API


## TODO
* ~~`wait-for` startup ordering for `keycloak` <- `oauth2-proxy` + `apiserver` (OIDC discovery)~~
* source chart somewhere.. NCSA Harbor? github pages?
* Verbose configuration documentation
* Adjust webui to speak `_oauth2_proxy` instead of / addition in speaking `keycloak` for OIDC
* MongoDB replication
* Git release workflows? CI? Github Actions?
