FROM alpine:latest

RUN apk update && apk upgrade
RUN apk add --no-cache tini tor
RUN \
    echo 'RunAsDaemon 0' >>/etc/tor/torrc && \
    echo 'ExitPolicy reject *:*' >>/etc/tor/torrc && \
    echo 'SocksPort 0.0.0.0:9050 IsolateDestAddr' >>/etc/tor/torrc && \
    echo 'Log notice stderr' >>/etc/tor/torrc

USER tor

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/tor"]
