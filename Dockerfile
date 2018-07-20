FROM node:8.11.3-alpine
# easier to install jdk than node !

ENV sbt_version="1.1.6" sbt_home="/usr/local/sbt" PATH="${PATH}:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin:/usr/local/sbt/bin:/google-cloud-sdk/bin" LANG="C.UTF-8" JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk" JAVA_VERSION="8u171" JAVA_ALPINE_VERSION="8.171.11-r0" KUBE_LATEST_VERSION="v1.10.2" HELM_VERSION="v2.9.1" CLOUD_SDK_VERSION="206.0.0"

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
    sbt sbtVersion

# Google Cloud SDK https://github.com/GoogleCloudPlatform/cloud-sdk-docker/blob/206.0.0/alpine/Dockerfile
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

# Kubectl https://github.com/dtzar/helm-kubectl/blob/master/Dockerfile
RUN apk add --no-cache ca-certificates bash git \
    && wget -q --no-check-certificate https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && wget -q --no-check-certificate http://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm


# install docker client
RUN mkdir -p /tmp/download \
    && curl -L https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz  | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download

# git-secret
# install gcc and g++ for bs-platform (OCaml compiler)
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
      >> /etc/apk/repositories && \
 apk --no-cache add gawk gcc musl-dev g++ gnupg && \
 git clone https://github.com/sobolevn/git-secret.git /tmp/git-secret --branch v0.2.3 && \
 cd /tmp/git-secret && make build && PREFIX="/usr/local" make install && \
 cd /tmp && rm -rf git-secret


CMD bash
