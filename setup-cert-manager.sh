#!/bin/bash
#
# Prereqs: sudo
#
# Usage: ./setup-cert-manager.sh <DOMAIN> [ALLOW_FROM_ADDRESS_RANGE]
#
set -e

# The final file NEEDS to be set to acmedns.json
CREDENTIALS_BASE="acmedns"
CREDENTIALS_RAW="${CREDENTIALS_BASE}.raw.json"
CREDENTIALS_STRIPPED="${CREDENTIALS_BASE}.stripped.json"
CREDENTIALS_FINAL="${CREDENTIALS_BASE}.json"

CM_NAMESPACE="cert-manager"
CM_VERSION="1.0.1"

DOMAIN="$1"
if [ "$1" == "" ]; then
	echo "Domain not specified. Aborting."
	echo "Usage: ./setup.sh <DOMAIN> [ALLOW_FROM_ADDRESS_RANGE]"
	exit 1
fi

# Install dependencies (e.g. curl)
sudo apt-get -qq update && \
sudo apt-get -qq install \
  curl \
  jq \
  apt-transport-https \
  ca-certificates

# Install cert-manager Helm chart
sudo helm repo add jetstack https://charts.jetstack.io
sudo helm repo update
kubectl get ns ${CM_NAMESPACE} || kubectl create ns ${CM_NAMESPACE}
sudo helm upgrade --install   cert-manager jetstack/cert-manager   --namespace ${CM_NAMESPACE}   --version v${CM_VERSION}  --set 'extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}' --set installCRDs=true

# TODO: Re-use previous registration?
# Register with ACME-DNS
if [ "$2" == "" ]; then
	curl -s -XPOST https://auth.acme-dns.io/register > ${CREDENTIALS_RAW}
else
	curl -s -XPOST https://auth.acme-dns.io/register -H "Content-Type: application/json" --data '{"allowfrom": ["$2"]}' > ${CREDENTIALS_RAW}
fi

# Output auth info as a sanity check
CREDENTIALS_JSON=$(cat ${CREDENTIALS_RAW})
echo \{\"$DOMAIN\":${CREDENTIALS_JSON},\"*.$DOMAIN\":${CREDENTIALS_JSON}} > ${CREDENTIALS_FINAL}
cat ${CREDENTIALS_FINAL}

# Add credentials as a Kubernetes secret
kubectl create secret -n ${CM_NAMESPACE} generic acme-dns --from-file ${CREDENTIALS_FINAL} --dry-run=client -o yaml | kubectl apply -f -

# Let the user know that they need to manually set this DNS record
echo
echo
echo "Please place the following CNAME record on your DNS provider:"
fulldomain="$(cat ${CREDENTIALS_RAW} | jq '.fulldomain')"
echo "_acme-challenge.${DOMAIN}	CNAME	${fulldomain}"
echo

echo "Once DNS propagates, you should be ready to issue certs"

