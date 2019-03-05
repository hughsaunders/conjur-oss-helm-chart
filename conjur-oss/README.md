# conjur-oss

[CyberArk Conjur Open Source](https://www.conjur.org) is a powerful secrets management solution,
tailored specifically to the unique infrastructure requirements of
native cloud, containers, and DevOps environments.
Conjur Open Source is part of the CyberArk Privileged Access Security Solution which is widely used by enterprises across the globe.

[![GitHub release](https://img.shields.io/github/release/cyberark/conjur-oss-helm-chart.svg)](https://github.com/cyberark/conjur-oss-helm-chart/releases/latest)
[![pipeline status](https://gitlab.com/cyberark/conjur-oss-helm-chart/badges/master/pipeline.svg)](https://gitlab.com/cyberark/conjur-oss-helm-chart/pipelines)

[![Github commits (since latest release)](https://img.shields.io/github/commits-since/cyberark/conjur-oss-helm-chart/latest.svg)](https://github.com/cyberark/conjur-oss-helm-chart/commits/master)

---

## Prerequisites

- Kubernetes 1.7+

## Installing the Chart

The Chart can be installed from a GitHub release Chart tarball or from source.

All releases: https://github.com/cyberark/conjur-oss-helm-chart/releases

### Simple install

Install latest Conjur with integrated Postgres.

```sh-session
$ helm install \
  --set dataKey="$(docker run --rm cyberark/conjur data-key generate)" \
  https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v<VERSION>/conjur-oss-<VERSION>.tgz
```

This will deploy the latest version of `cyberark/conjur`.
The Conjur `ClusterIP` service is not exposed outside the cluster.
Conjur is running HTTPS on port 443 (9443 within the cluster) with a self-signed
certificate. A PostgreSQL deployment is created to store Conjur state.

Note that you can also install from source by cloning this repository and running

```sh-session
helm install \
  --set dataKey="$(docker run --rm cyberark/conjur data-key generate)" \
  ./conjur-oss
```

### Custom Installation

All important chart values can be customized and the following shows how to install
a specific version of Conjur, enable additional Kubernetes-API authentications,
generate self-signed SSL certificates, expose Conjur outside of the cluster,
and configure it to connect to a remote database:

**custom-values.yaml**

```yaml
authenticators: "authn-k8s/minikube,authn"
dataKey: "GENERATED_DATAKEY"  # docker run --rm -it cyberark/conjur data-key generate
databaseUrl: "postgres://postgres:PASSWORD@POSTGRES_ENDPOINT/postgres"

image:
  tag: "1.1.1-stable"
  pullPolicy: IfNotPresent

ssl:
  hostname: custom.domainname.com
```

```sh-session
$ helm install -f custom-values.yaml \
  https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v<VERSION>/conjur-oss-<VERSION>.tgz
```

*NOTE:* If using the Kubernetes authenticator for Conjur, the `account` value
(see [Configuration](#Configuration)) must match the initial Conjur account
created. For example, given the following command:

```sh-session
$ kubectl exec $POD_NAME --container=conjur-oss conjurctl account create example
```

The chart value for `account` would be expected to equal `example`.

## TLS with Lets Encrypt
Conjur can be deployed using a lets encrypt certificate.

### Prerequisites
1. An ingress controller. This method has been tested with nginx but may also
   work with others. If you don't have an ingress controller, you can deploy the
   nginx ingress controller with:
   ```shell
   helm install stable/nginx-ingress --name nginx-ingress
   ```
1. A public wildcard DNS entry pointing at the ingress controller's IP. Cert manager
   will create temporary pods to prove domain ownership, this process will fail
   if the DNS record doesn't already exist.
1. [cert-manager](https://github.com/jetstack/cert-manager). This is a
   kubernetes service that manages certificates. It speaks the [Let's Encrypt
   ACME protocol](https://letsencrypt.org/how-it-works/), and hooks into ingress
   resource lifecycle events so that certs are created when required. If
   cert-manager is not already configured in your cluster, you can use the
   included script:
   ```shell
   email="your.account@your.provider" ./conjur-oss/e2e/install-cert-manager.sh
   ```
1. Custom values file. This should disable the external service, enable the
   ingress object specifying the relevant issuer, and specify the hostname to
   use for certificates. Note that the cert-manager install script creates two
   issuers letsencrypt-staging and letsencrypt-production. Production has strict
   rate limits but also is widely trusted. Staging has more generous limits but
   is not trusted. If you deployed cert-manager independently, you can get a
   list of issuers with:
   ```shell
   kubectl get issuer
   ```
   Example custom values file:
   ```yaml
    service:
      external:
        enabled: false
    ingress:
      enabled: true
      issuer: letsencrypt-production
    ssl:
      hostname: "conjur.myorg.com"
   ```
   These values can be combined with the values specified above in the custom deployment section.

Once the above is in place, the chart can be deployed as before, but referencing the custom values file:
```shell
helm install \
  -f custom-values.yaml
  --set dataKey="$(docker run --rm cyberark/conjur data-key generate)" \
  https://github.com/cyberark/conjur-oss-helm-chart/releases/download/v<VERSION>/conjur-oss-<VERSION>.tgz
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```
$ helm delete my-release
```

The command removes all the Kubernetes components
associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Conjur OSS chart and their default values.

|Parameter|Description|Default|
|---------|-----------|-------|
|`account`|Name of the Conjur account to be used by the Kubernetes authenticator|`"default"`|
|`authenticators`|List of authenticators that Conjur will whitelist and load.|`"authn"`|
|`conjurLabels`|Extra Kubernetes labels to apply to Conjur resources|`{}`|
|`databaseUrl`|PostgreSQL connection string. If left blank, a PostgreSQL deployment is created.|`""`|
|`dataKey`|Conjur data key, 32 byte base-64 encoded string for data encryption.|`""`|
|`deployment.annotations`|Annotations for Conjur deployment|`{}`|
|`image.repository`|Conjur Docker image repository|`"cyberark/conjur"`|
|`image.tag`|Conjur Docker image tag|`"latest"`|
|`image.pullPolicy`|Pull policy for Conjur Docker image|`"Always"`|
|`nginx.image.repository`|NGINX Docker image repository|`"nginx"`|
|`nginx.image.tag`|NGINX Docker image tag|`"1.15"`|
|`nginx.image.pullPolicy`|Pull policy for NGINX Docker image|`"IfNotPresent"`|
|`postgres.image.pullPolicy`|Pull policy for postgres Docker image|`"IfNotPresent"`|
|`postgres.image.repository`|postgres Docker image repository|`"postgres"`|
|`postgres.image.tag`|postgres Docker image tag|`"10.1"`|
|`postgres.persistentVolume.create`|Create a peristent volume to back the PostgreSQL data|`true`|
|`postgres.persistentVolume.size`|Size of persistent volume to be created for PostgreSQL|`"8Gi"`|
|`postgres.persistentVolume.storageClass`|Storage class to be used for PostgreSQL persistent volume claim|`nil`|
|`rbac.create`|Controls whether or not RBAC resources are created|`true`|
|`replicaCount`|Number of desired Conjur pods|`1`|
|`service.external.annotations`|Annotations for the external LoadBalancer|`[service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp]`|
|`service.external.enabled`|Expose service to the Internet|`true`|
|`service.external.port`|Conjur external service port|`443`|
|`service.internal.annotations`|Annotations for Conjur service|`{}`|
|`service.internal.port`|Conjur internal service port|`443`|
|`service.internal.type`|Conjur internal service type (ClusterIP and NodePort supported)|`"NodePort"`|
|`serviceAccount.create`|Controls whether or not a service account is created|`true`|
|`serviceAccount.name`|Name of the ServiceAccount to be used by access-controlled resources created by the chart|`nil`|
|`ssl.altNames`|Subject Alt Names for generated Conjur certificate and ingress|`[]`|
|`ssl.expiration`|Expiration limit for generated certificates|`365`|
|`ssl.hostname`|Hostname and Common Name for generated certificate and ingress|`"conjur.myorg.com"`|
|`postgresLabels`|Extra Kubernetes labels to apply to Conjur PostgreSQL resources|`{}`|

## Contributing

This chart is maintained at
[github.com/cyberark/conjur-oss-helm-chart](https://github.com/cyberark/conjur-oss-helm-chart).
