ARG alpine_version=3.18.5

FROM alpine:${alpine_version} as base
RUN apk update && apk upgrade

#
# git-gau build stage
#
FROM base as gitgau-build

RUN apk add --no-cache make

RUN mkdir /src /dist

ARG gitgau_ref=v1.1.0
ENV gitgau_ref ${gitgau_ref}

ADD "https://codeload.github.com/znerol/git-gau/tar.gz/${gitgau_ref}" /src/git-gau-src.tar.gz
RUN tar -o -C /src -xf /src/git-gau-src.tar.gz
RUN make -C /src/git-gau-* prefix=/dist install-bin

#
# certhub build stage
#
FROM base as certhub-build

RUN apk add --no-cache make

RUN mkdir /src /dist

ARG certhub_ref=v1.0.0-beta9
ENV certhub_ref ${certhub_ref}

ADD "https://codeload.github.com/certhub/certhub/tar.gz/${certhub_ref}" /src/certhub-src.tar.gz
RUN tar -o -C /src -xf /src/certhub-src.tar.gz
RUN make -C /src/certhub-* prefix=/dist install-bin

#
# dehydrated build stage
#
FROM base as dehydrated-build

RUN apk add --no-cache ca-certificates poetry python3 py3-beautifulsoup4 py3-cffi py3-cryptography py3-filelock py3-openssl py3-pip py3-requests py3-yaml py3-lxml py3-tldextract

RUN mkdir /src /dist /etc-dist

ARG lexicon_ref=v3.17.0
ENV lexicon_ref ${lexicon_ref}

ADD "https://codeload.github.com/AnalogJ/lexicon/tar.gz/${lexicon_ref}" /src/lexicon-src.tar.gz
RUN tar -o -C /src -xf /src/lexicon-src.tar.gz

RUN (cd /src/lexicon-* && poetry build)

ENV PIP_DISABLE_PIP_VERSION_CHECK 1
RUN pip3 install --prefix=/dist /src/lexicon-*/dist/dns_lexicon-*-py3-none-any.whl

ARG dehydrated_version=v0.7.1
ENV dehydrated_version ${dehydrated_version}

ADD "https://raw.githubusercontent.com/dehydrated-io/dehydrated/$dehydrated_version/dehydrated" /dist/bin/dehydrated
ADD "https://raw.githubusercontent.com/dehydrated-io/dehydrated/$dehydrated_version/docs/examples/config" /etc-dist/dehydrated/config
RUN chmod 0755 /dist/bin/dehydrated && chmod 0644 /etc-dist/dehydrated/config

#
# docs stage
#
FROM base as docs-build

RUN mkdir /dist /dist-etc

ARG build_log_url
ENV build_log_url ${build_log_url}

ARG build_log_label
ENV build_log_label ${build_log_label}

COPY . /src

RUN if [ -n "${build_log_url}" ] && [ -n "${build_log_label}" ]; then \
    sed -i "s|.*Build Status.*$|Build Log: [${build_log_label}](${build_log_url})|g" /src/README.md; \
    fi
RUN install -m 0644 -D /src/README.md /dist-etc/motd && \
    install -m 0755 -D /src/docker-entry.d/00-motd /dist/lib/git-gau/docker-entry.d/00-motd

#
# runtime image stage
#
FROM base

RUN apk add --no-cache bash ca-certificates curl git openssh-client openssl python3 py3-beautifulsoup4 py3-cffi py3-cryptography py3-filelock py3-openssl py3-pip py3-requests py3-yaml py3-lxml py3-tldextract tini tzdata

COPY --from=gitgau-build /dist /usr
COPY --from=certhub-build /dist /usr
COPY --from=dehydrated-build /dist /usr
COPY --from=dehydrated-build /etc-dist /etc
COPY --from=docs-build /dist /usr
COPY --from=docs-build /dist-etc /etc

RUN addgroup -S certhub && adduser -S certhub -G certhub && \
    mkdir /etc/dehydrated/accounts && \
    chown -R certhub.certhub /etc/dehydrated

USER certhub

ENTRYPOINT [ \
    "/sbin/tini", \
    "--", \
    "/usr/bin/ssh-agent", \
    "/usr/lib/git-gau/docker-entry", \
    "/usr/lib/git-gau/docker-entry.d" \
]
