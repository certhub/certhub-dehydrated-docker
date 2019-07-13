#!/bin/sh

set -e
set -u
set -x

CONFIG_CSR_DIR=$(dirname "${CONFIG_CSR_PATH}")
mkdir -p "${CONFIG_CSR_DIR}"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 | \
    openssl req -new -subj "/CN=${CONFIG_CERT_CN}/" -key - -out "${CONFIG_CSR_PATH}"

CONFIG_DEHYDRATED_CONF_DIR=$(dirname "${CONFIG_DEHYDRATED_CONF_PATH}")
mkdir -p "${CONFIG_DEHYDRATED_CONF_DIR}"

cat <<EOF > "${CONFIG_DEHYDRATED_CONF_PATH}"
CA="https://acme-staging-v02.api.letsencrypt.org/directory"
CHALLENGETYPE="dns-01"
BASEDIR=/etc/dehydrated
HOOK=/usr/lib/certhub/dehydrated-hooks/lexicon-auth
CURL_OPTS="--proxy socks5h://tor:9050"
IP_VERSION="4"
EOF
