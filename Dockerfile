# ruby is hard to install because rvm doesn't work in Docker
FROM ruby:2.3.7-slim-stretch

ENV LANG="C.UTF-8" \
    SBT_VERSION="1.1.6" \
    NODE_VERSION="8.11.3" \
    GOPATH=$HOME/work \
    PATH=$PATH:/usr/local/go/bin:$HOME/work/bin \
    AWS_SDK_LOAD_CONFIG="true" \
    AWS_REGION="eu-west-1" \
    DOCKER_AUTH_CONFIG="{\"credsStore\":\"ecr-login\"}"

RUN \
    mkdir $HOME/work && \
    ruby -v && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install --no-install-recommends -y \
        apt-utils openjdk-8-jdk-headless lsb-release build-essential apt-transport-https ca-certificates curl \
        gnupg2 software-properties-common git ssh tar wget default-libmysqlclient-dev ruby-mysql2 awscli golang-go make

# sbt
# Taken from https://github.com/hseeberger/docker-sbt
RUN \
    curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
    dpkg -i sbt-$SBT_VERSION.deb && \
    rm sbt-$SBT_VERSION.deb && \
    apt-get update && \
    apt-get install --no-install-recommends -y sbt && \
    sbt sbtVersion

# GCloud
## Create an environment variable for the correct distribution
RUN \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    ## Add the Cloud SDK distribution URI as a package source
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    ## Import the Google Cloud Platform public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# NodeJS
RUN \
    curl -L https://git.io/n-install | bash -s -- -y && \
    /root/n/bin/n $NODE_VERSION && \
    node -v

# Docker && Google Cloud CLI && Kubernetes CLI
RUN \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get remove -y docker docker-engine docker.io && \
    apt-get install --no-install-recommends -y moreutils jq google-cloud-sdk kubectl docker-ce && \
    apt-get install -y python-pip && \
    pip install yq && \
    usermod -aG docker root

# https://github.com/awslabs/amazon-ecr-credential-helper
# Required because of this: https://gitlab.com/gitlab-org/gitlab-runner/issues/1583
#
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login && \
    docker-credential-ecr-login version

# Helm
RUN \
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

# git-secret
RUN \
    echo "deb https://dl.bintray.com/sobolevn/deb git-secret main" | tee -a /etc/apt/sources.list && \
    wget -qO - https://api.bintray.com/users/sobolevn/keys/gpg/public.key | apt-key add -  && \
    apt-get update && \
    apt-get install --no-install-recommends -y git-secret

# Clean
RUN \
    apt-get purge -y python-pip apt-utils && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD bash
