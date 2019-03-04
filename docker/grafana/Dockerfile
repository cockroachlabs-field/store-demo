FROM grafana/grafana

LABEL maintainer="tjveil@gmail.com"

ADD ./provisioning /etc/grafana/provisioning
ADD ./config.ini /etc/grafana/config.ini
ADD ./dashboards /var/lib/grafana/dashboards

EXPOSE 3000