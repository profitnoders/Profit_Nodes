FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget unzip tzdata \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/filtitanagent

RUN wget -q https://pcdn.titannet.io/filpcdn/bin/filagent/filagent-linux.zip -O /tmp/filagent-linux.zip \
 && unzip -o /tmp/filagent-linux.zip -d /opt/filtitanagent \
 && chmod +x /opt/filtitanagent/filagent \
 && rm -f /tmp/filagent-linux.zip

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/data"]
ENTRYPOINT ["/entrypoint.sh"]
