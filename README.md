# docker-elasticsearch

Containerized, ARM version of elasticsearch. Compatible with Raspberry Pi

## How to Build

Build using `buildx` for multiarchitecture image and manifest support

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
docker buildx build --platform linux/arm -t jmb12686/elasticsearch:latest --push .
```

## How to Run

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
