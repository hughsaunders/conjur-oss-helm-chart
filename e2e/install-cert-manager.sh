#!/bin/bash -e
# Information from:
# https://github.com/helm/charts/tree/master/stable/cert-manager
# https://cert-manager.readthedocs.io/en/release-0.6/tutorials/acme/quick-start/index.html#


# Shopts
set -o pipefail

# Vars
ns="${ns:-kube-system}"
release=${release:-"cert-manager"}

# Pre-Requisites

# 1. Helm installed, see install-helm.sh
helm list >/dev/null \
    || { echo "Helm must be installed and functioning before cert-manager can be installed."; exit 1; }

# 2. Email env var set
[[ -z "${email}" ]] && { echo "email env var must be set when enabling lets encrypt"; exit 1; }


# Add CRDs
kubectl apply \
    -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml

# Add disable validation to namespace if namespace exists
kubectl get ns/${ns} &>/dev/null \
    && kubectl label --overwrite namespace ${ns} certmanager.k8s.io/disable-validation="true"

# No need to add the stable repo, as helm init creates it

# install or upgrade the cert-manager chart
helm upgrade --install --namespace ${ns} ${release} stable/cert-manager

# create issuers for staging and production enviornments

issuer(){
    name="${1}"
    server="${2}"
    email="${3}"

    kubectl --namespace ${ns} apply -f - <<EOF
apiVersion: certmanager.k8s.io/v1alpha1
kind: Issuer
metadata:
    name: ${name}
spec:
    acme:
        # The ACME server URL
        server: "${server}"
        # Email address used for ACME registration
        email: ${email}
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef:
            name: ${name}
        # Enable the HTTP-01 challenge provider
        http01: {}
EOF

}
issuer \
    "letsencrypt-staging" \
    "https://acme-staging-v02.api.letsencrypt.org/directory" \
    "${email}"
issuer \
    "letsencrypt-production" \
    "https://acme-v02.api.letsencrypt.org/directory" \
    "${email}"
