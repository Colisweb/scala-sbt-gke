# ruby is hard to install because rvm doesn't work in Docker
FROM ruby:2.3.7-slim-stretch

ENV LANG="C.UTF-8" \
    SBT_VERSION="1.1.6" \
    NODE_VERSION="8.11.4" \
    KUBECTL_VERSION="1.12.1" \
    AWS_AUHTENTICATOR_VERSION="0.3.0"

RUN \
    ruby -v && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install --no-install-recommends -y \
        apt-utils openjdk-8-jdk-headless lsb-release build-essential apt-transport-https ca-certificates curl \
        gnupg2 software-properties-common git ssh tar wget default-libmysqlclient-dev ruby-mysql2 \
        python-dev python3-dev python-pip

# sbt
# Taken from https://github.com/hseeberger/docker-sbt
RUN \
    curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
    dpkg -i sbt-$SBT_VERSION.deb && \
    rm sbt-$SBT_VERSION.deb && \
    apt-get update && \
    apt-get install --no-install-recommends -y sbt && \
    sbt sbtVersion

# NodeJS
RUN \
    curl -L https://git.io/n-install | bash -s -- -y && \
    /root/n/bin/n $NODE_VERSION && \
    node -v

# AWS CLI
RUN \
    curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip install awscli --upgrade --user

# Docker
RUN \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get remove -y docker docker-engine docker.io && \
    apt-get install --no-install-recommends -y moreutils jq docker-ce && \
    pip install yq && \
    usermod -aG docker root

# Kubernetes CLI
RUN \
    curl -L "https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl
RUN \
    curl -L "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v$AWS_AUHTENTICATOR_VERSION/heptio-authenticator-aws_${AWS_AUHTENTICATOR_VERSION}_linux_amd64" -o /usr/local/bin/aws-iam-authenticator && \
    chmod +x /usr/local/bin/aws-iam-authenticator

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
    apt-get purge -y apt-utils && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD bash
