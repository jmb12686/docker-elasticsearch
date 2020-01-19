################################################################################
# This Dockerfile was generated from the template at distribution/src/docker/Dockerfile
#
# Beginning of multi stage Dockerfile
################################################################################

################################################################################
# Build stage 0 `builder`:
# Extract elasticsearch artifact
# Install required plugins
# Set gid=0 and make group perms==owner perms
################################################################################

FROM centos:7 AS builder

ENV VERSION 7.4.1
ENV PATH /usr/share/elasticsearch/bin:$PATH

RUN groupadd -g 1000 elasticsearch &&     adduser -u 1000 -g 1000 -d /usr/share/elasticsearch elasticsearch

WORKDIR /usr/share/elasticsearch

RUN cd /opt && curl --retry 8 -s -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}-no-jdk-linux-x86_64.tar.gz -# && cd -
RUN cd /opt && curl --retry 8 -s -L -O https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.6%2B10/OpenJDK11U-jdk_arm_linux_hotspot_11.0.6_10.tar.gz && cd -

RUN tar zxf /opt/elasticsearch-${VERSION}-no-jdk-linux-x86_64.tar.gz --strip-components=1
# RUN rm -rf /usr/share/elasticsearch/jdk/*
RUN mkdir jdk
RUN tar zxf /opt/OpenJDK11U-jdk_arm_linux_hotspot_11.0.6_10.tar.gz -C jdk --strip-components=1

RUN rm -rf /usr/share/elasticsearch/jdk/lib/src.zip && rm -rf /usr/share/elasticsearch/jdk/demo

RUN grep ES_DISTRIBUTION_TYPE=tar /usr/share/elasticsearch/bin/elasticsearch-env     && sed -ie 's/ES_DISTRIBUTION_TYPE=tar/ES_DISTRIBUTION_TYPE=docker/' /usr/share/elasticsearch/bin/elasticsearch-env
RUN mkdir -p config data logs
RUN chmod 0775 config data logs
COPY config/log4j2.properties config/

################################################################################
# Build stage 1 (the actual elasticsearch image):
# Copy elasticsearch from stage 0
# Add entrypoint
################################################################################

FROM debian

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="John Belisle" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="elasticsearch" \
  org.label-schema.description="Containerized, ARM version of elasticsearch.  Compatible with all Raspberry Pi models (armv6 + armv7) and linux/amd64." \
  org.label-schema.version=$VERSION \
  org.label-schema.url="https://github.com/jmb12686/docker-elasticsearch" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/jmb12686/docker-elasticsearch" \
  org.label-schema.vendor="jmb12686" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.docker.cmd="sudo docker run \
  --volume=/var/run/docker.sock:/var/run/docker.sock:ro \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=elasticsearch \
  jmb12686/elasticsearch:latest"
ENV ELASTIC_CONTAINER true

RUN for iter in {1..10}; \
    do \
		  apt update  -y && apt install -y  netcat \
		  && apt install -y dos2unix \
		  && apt autoremove -y && apt clean && exit_code=0 \
		  && break || exit_code=$? \
		  && echo "apt error: retry $iter in 10s" \
		  && sleep 10; \
		done;\
		(exit $exit_code) \
		&& groupadd -g 1000 elasticsearch && useradd -u 1000 -g 1000 -G 0 -m -d /usr/share/elasticsearch elasticsearch \
		&& chmod 0775 /usr/share/elasticsearch && chgrp 0 /usr/share/elasticsearch

WORKDIR /usr/share/elasticsearch
COPY --from=builder --chown=1000:0 /usr/share/elasticsearch /usr/share/elasticsearch

ENV PATH /usr/share/elasticsearch/bin:$PATH

COPY --chown=1000:0 bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0
# Allow ENTRYPOINT (and ES) to run even with a different user

# Replace OpenJDK's built-in CA certificate keystore with the one from the OS
# vendor. The latter is superior in several ways.
# REF: https://github.com/elastic/elasticsearch-docker/issues/171

RUN chgrp 0 /usr/local/bin/docker-entrypoint.sh && chmod g=u /etc/passwd && chmod 0775 /usr/local/bin/docker-entrypoint.sh \
    && dos2unix /usr/local/bin/docker-entrypoint.sh \
	&& ln -sf /etc/pki/ca-trust/extracted/java/cacerts /usr/share/elasticsearch/jdk/lib/security/cacerts

EXPOSE 9200 9300

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["eswrapper"]

################################################################################
# End of multi-stage Dockerfile
################################################################################
