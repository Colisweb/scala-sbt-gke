FROM hseeberger/scala-sbt:8u141-jdk_2.12.3_0.13.16

MAINTAINER Colisweb

RUN apt-get update && install -y lsb-release build-essential apt-transport-https ca-certificates curl gnupg2 software-properties-common

# GCloud
## Create an environment variable for the correct distribution
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
## Add the Cloud SDK distribution URI as a package source
RUN echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
## Import the Google Cloud Platform public key
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# NodeJS
RUN curl -L https://git.io/n-install | bash -s -- -y
RUN /root/n/bin/n 8.5.0

# Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

RUN apt-get update
RUN apt-get remove -y docker docker-engine docker.io
RUN apt-get install -y moreutils python-pip jq google-cloud-sdk kubectl docker-ce
RUN pip install --upgrade pip
RUN pip install yq

CMD echo "finished"