# docker-elasticsearch

<p align="center">
  <a href="https://hub.docker.com/r/jmb12686/elasticsearch/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/jmb12686/docker-elasticsearch?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/jmb12686/docker-elasticsearch/actions"><img src="https://github.com/jmb12686/docker-elasticsearch/workflows/build/badge.svg" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/jmb12686/elasticsearch/"><img src="https://img.shields.io/docker/stars/jmb12686/elasticsearch.svg?style=flat-square" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/jmb12686/elasticsearch/"><img src="https://img.shields.io/docker/pulls/jmb12686/elasticsearch.svg?style=flat-square" alt="Docker Pulls"></a>
</p>

Containerized, multiarch version of [Elasticsearch](https://github.com/elastic/elasticsearch).  Designed to be usable within x86-64, armv6, and armv7 based Docker Swarm clusters.  Compatible with all Raspberry Pi models (armv6 + armv7).

## Usage

Run on a single Docker engine node:

```bash
sudo docker run --rm -e "ES_JAVA_OPTS=-Xmx256m -Xms256m" -e "discovery.type=single-node" -v ${PWD}/config/example/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml jmb12686/elasticsearch
```

Run with with Compose on Docker Swarm:

```yml
version: "3.7"
services:
  elasticsearch:
    image: jmb12686/elasticsearch
    configs:
      - source: elastic_config
        target: /usr/share/elasticsearch/config/elasticsearch.yml
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    environment:
      ES_JAVA_OPTS: "-Xmx256m -Xms256m"
      ELASTIC_PASSWORD: changeme
      discovery.type: single-node
    networks:
      - elk
    deploy:
      mode: replicated
      replicas: 1
      resources:
        limits:
          memory: 1024M
        reservations:
            memory: 1024M
configs:
  elastic_config:
    name: elastic_config-${CONFIG_VERSION:-0}
    file: ./elasticsearch/config/elasticsearch.yml
networks:
  elk:
    driver: overlay

volumes:
  filebeat: {}
  elasticsearch-data: {}
```

## How to manually build

Build using `buildx` for multiarchitecture image and manifest v2 support

Setup buildx

```bash
docker buildx create --name multiarchbuilder
docker buildx use multiarchbuilder
docker buildx inspect --bootstrap
[+] Building 0.0s (1/1) FINISHED
 => [internal] booting buildkit                                                                                                                 5.7s
 => => pulling image moby/buildkit:buildx-stable-1                                                                                              4.6s
 => => creating container buildx_buildkit_multiarchbuilder0                                                                                     1.1s
Name:   multiarchbuilder
Driver: docker-container

Nodes:
Name:      multiarchbuilder0
Endpoint:  npipe:////./pipe/docker_engine
Status:    running
Platforms: linux/amd64, linux/arm64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```

Build

```bash
docker buildx build --platform linux/arm,linux/amd64 -t jmb12686/elasticsearch:latest --push .
```
