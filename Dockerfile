FROM ubuntu:16.04

# RUN apk add --no-cache bash iptables && \
#         rm -rf /var/cache/apk/*
RUN apt-get update && \
        apt-get install -y iptables iproute2

USER root

ADD entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/root/entrypoint.sh"]
