#!/bin/sh

set -e
set -u
set -x

git gau-ac \
git gau-xargs -I"{WORKDIR}" \
certhub-message-format "${CERTHUB_CERT_PATH}" x509 \
certhub-dehydrated-run "${CERTHUB_CERT_PATH}" "${CERTHUB_CSR_PATH}" \
dehydrated ${CERTHUB_DEHYDRATED_ARGS} --config "${CERTHUB_DEHYDRATED_CONFIG}"
