FROM prom/prometheus:latest

LABEL maintainer="tjveil@gmail.com"

ADD prometheus.yml /etc/prometheus/
ADD aggregation.rules.yml /etc/prometheus/

EXPOSE 9090