ARG DOCKER_VERSION=v23.0.0
ARG COMPOSE_VERSION=v2.17.2
ARG BASE_IMAGE_TAG=18-bullseye-slim

FROM qmcgaw/binpot:docker-${DOCKER_VERSION} AS docker
FROM qmcgaw/binpot:compose-${COMPOSE_VERSION} AS compose

FROM node:${BASE_IMAGE_TAG}

# node may come with an older version of npm. Ensure we have a specific npm.
ARG NPM_VERSION=latest
RUN npm install -g npm@${NPM_VERSION}

################################################################################
# Install prerequisites
RUN apt-get update && apt-get --no-install-recommends --yes install \
    groff less curl git ca-certificates unzip zsh locales && \
    update-ca-certificates && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm awscliv2.zip && \
    rm -rf ./aws && \
    apt-get --yes remove unzip && \
    apt-get --yes autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/*

# Setup shell
ENV LANG=en_US.UTF-8
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8

ARG POWERLEVEL10K_VERSION=v1.16.1
RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /home/node/.oh-my-zsh && \
    git clone --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git /home/node/.oh-my-zsh/custom/themes/powerlevel10k && \
    rm -rf /home/node/.oh-my-zsh/custom/themes/powerlevel10k/.git

RUN chsh -s /bin/zsh node

# Docker CLI
COPY --from=docker /bin /usr/local/bin/docker
ENV DOCKER_BUILDKIT=1
RUN chmod 705 /usr/local/bin/docker

# Docker compose
COPY --from=compose /bin /usr/libexec/docker/cli-plugins/docker-compose
ENV COMPOSE_DOCKER_CLI_BUILD=1
RUN chmod 705 /usr/libexec/docker/cli-plugins/docker-compose