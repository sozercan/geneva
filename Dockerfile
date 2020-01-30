# inspired by https://msazure.visualstudio.com/One/_git/Compute-Runtime-Tux-GenevaContainers?path=%2Fdocker_geneva_mdsd%2FDockerfile
FROM ubuntu:18.04

LABEL name="docker_geneva_base" \
      version="1.0" \
      description="Build base container shared by several Geneva application containers" \
      author="octaviah@microsoft.com" \
      maintainer="azlinux@microsoft.com" \
      repo="https://msazure.visualstudio.com/One/_git/Compute-Runtime-Tux-GenevaContainers"

# Define working directory.
WORKDIR /

# switch to azure mirror
RUN sed -i "s://archive\.ubuntu\.com/://azure.archive.ubuntu.com/:" /etc/apt/sources.list

# Update cache
RUN apt-get update -qq -y && \
    apt-get upgrade -qq

# install https transport which is required for packages.microsoft.com repo
RUN apt-get install -y apt-transport-https gnupg ca-certificates curl

# Add packages.microsoft.com repo for mdm/mdsd packages
ADD azure-public-bionic.list /etc/apt/sources.list.d/azure-public-bionic.list
RUN curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl -s https://packages.microsoft.com/keys/msopentech.asc | apt-key add -
RUN apt-key list

# Update cache
RUN apt-get update

# Add Production repo client for Azure
RUN apt-get install -y azure-repoclient-https-noauth-public-bionic

# Install apt-utils
RUN apt-get install -y --no-install-recommends apt-utils

# Update CA Root Certs
RUN apt-get install -y ca-certificates

# Update cache and upgrade base packages
RUN apt-get upgrade -y

# Install tools
RUN apt-get install -y vim
RUN apt-get install -y netcat
RUN apt-get install -y net-tools
RUN apt-get install -y iputils-ping
RUN apt-get install -y gdebi-core

# Install MDSD
# Copy in the script that will determine which package to install
COPY install_mdsd.sh /
RUN chmod +x /install_mdsd.sh
RUN /install_mdsd.sh
RUN rm -Rf /install_mdsd.sh

# mdsd startup script
COPY start_mdsd.sh /

CMD ["/bin/bash", "-c", "/start_mdsd.sh"]
