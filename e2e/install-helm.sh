#!/bin/bash -e

# Ensure current user has admin role before creating tiller rolebinding.
# for GCE:
# https://cloud.google.com/solutions/continuous-integration-helm-concourse
# kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

kubectl create -f rbac-config.yaml

helm init --service-account tiller
