FROM alpine:3.4

RUN apk add --no-cache \
        bash \
        iptables \
        iproute2 \
        openvpn \
        && rm -rf /var/cache/apk/*

USER root

ADD entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
