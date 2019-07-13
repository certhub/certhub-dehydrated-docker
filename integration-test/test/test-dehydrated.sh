#!/bin/sh

set -e
set -u
set -x

# Try to connect through tor before attempting to run dehydrated.
curl --output /dev/null --proxy tor:9050 --retry-connrefused --retry 3 'https://check.torproject.org/'

git gau-ac \
git gau-xargs -I"{WORKDIR}" \
certhub-message-format "${CERTHUB_CERT_PATH}" x509 \
certhub-dehydrated-run "${CERTHUB_CERT_PATH}" "${CERTHUB_CSR_PATH}" \
dehydrated ${CERTHUB_DEHYDRATED_ARGS} --config "${CERTHUB_DEHYDRATED_CONFIG}"
