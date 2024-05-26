FROM ubuntu:22.04

ENV TZ=America/New_York
ARG DEBIAN_FRONTEND=noninteractive

# install initial dependencies and tools
RUN apt update && \
    apt install -y sudo zip curl gnupg git make build-essential software-properties-common wget ca-certificates awscli vim

# install Docker
RUN for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update && \
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# install Nodejs
ENV NODE_MAJOR=20
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list && \
    apt update && \
    apt install -y nodejs && \
    npm install -g yarn

# install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint && \ 
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list && \  
    apt update && \
    apt install -y terraform

ARG USERNAME=${USERNAME}    
RUN useradd -o -u 1000 -m ${USERNAME} -s /bin/bash && \
    usermod -aG sudo ${USERNAME} && \
    usermod -aG docker ${USERNAME} && \
    newgrp docker && \
    echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${USERNAME} && \
    mkdir /workspace

USER ${USERNAME}