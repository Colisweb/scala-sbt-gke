# ruby is hard to install because rvm doesn't work in Docker
FROM colisweb/adoptjruby:adoptopenjdk-11.0.3-slim-9.2.7.0

ENV LANG="C.UTF-8" \
    SBT_VERSION="1.2.8" \
    NODE_VERSION="8.11.3"

RUN \
    ruby -v && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install --no-install-recommends -y \
        apt-utils lsb-release build-essential apt-transport-https ca-certificates curl \
        gnupg2 software-properties-common git ssh tar wget gnupg-agent && \
    gem update --system && \
    gem install bundler jar-dependencies ruby-maven && gem update bundler && bundle -v

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
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get remove -y docker docker-engine docker.io containerd runc && \
    apt-get install --no-install-recommends -y moreutils jq google-cloud-sdk kubectl docker-ce docker-ce-cli containerd.io && \
    apt-get install -y python-pip && \
    pip install yq && \
    usermod -aG docker root

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
