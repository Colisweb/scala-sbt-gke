#FROM openjdk:8u171-jdk-alpine3.7
FROM node:10.5.0-alpine
# easier to install jdk than node !

ENV sbt_version="1.1.6" sbt_home="/usr/local/sbt" PATH="${PATH}:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin:/usr/local/sbt/bin" LANG="C.UTF-8" JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk" JAVA_VERSION="8u171" JAVA_ALPINE_VERSION="8.171.11-r0"

# install openjdk https://github.com/docker-library/openjdk/blob/dd54ae37bc44d19ecb5be702d36d664fed2c68e4/8/jdk/alpine/Dockerfile
# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
  echo '#!/bin/sh'; \
  echo 'set -e'; \
  echo; \
  echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
} > /usr/local/bin/docker-java-home \
&& chmod +x /usr/local/bin/docker-java-home

RUN set -x \
  && apk add --no-cache openjdk8="$JAVA_ALPINE_VERSION" \ 
  && [ "$JAVA_HOME" = "$(docker-java-home)" ]


# install sbt: https://hub.docker.com/r/gafiatulin/alpine-sbt/~/dockerfile/
RUN apk --no-cache --update add bash curl wget make git && mkdir -p "$sbt_home" && \
    wget -q --no-check-certificate -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
    wget -q --no-check-certificate https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && apk add glibc-2.25-r0.apk && rm glibc-2.25-r0.apk && \
    wget -qO - --no-check-certificate "https://github.com/sbt/sbt/releases/download/v$sbt_version/sbt-$sbt_version.tgz" | tar xz -C $sbt_home --strip-components=1 && \
    apk del wget && \
    sbt sbtVersion

# Google Cloud SDK
ENV CLOUD_SDK_VERSION 206.0.0

ENV PATH /google-cloud-sdk/bin:$PATH
RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        git \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version
