#!/bin/bash
# 
# This script will generate a self-signed TLS certificate for the given domain. If no domain is specified, the user will be prompted for one.
#
# Usage: ./generate-self-signed-cert.sh [domain]
#

ECHO="echo -e"
domain="$1"

mkdir -p certs/

if [ "$domain" == "" ]; then
    $ECHO "Please specify a domain for your new certificate."
    read -p "Domain: " domain
fi

# Still no domain? Exit with error..
if [ "$domain" == "" ]; then
    $ECHO "You must specify a domain"
    exit 1
fi

if [ ! -f "certs/${domain}.cert" ]; then
    $ECHO "\nGenerating self-signed certificate for $domain"
    openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$domain" -newkey rsa:2048 -keyout "certs/$domain.key" -out "certs/$domain.cert"
else
    $ECHO "Certificate already exists for $domain... skipping generation of self-signed certificate"
fi
