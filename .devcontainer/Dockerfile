FROM ubuntu:noble

RUN if id "ubuntu" &>/dev/null; then \
        echo "Deleting user 'ubuntu'" && userdel -f -r ubuntu || echo "Failed to delete ubuntu user"; \  
    else \
        echo "User 'ubuntu' does not exist"; \ 
    fi

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    # Restore man command
    && yes | unminimize 2>&1 

ENV LANG="C.UTF-8"

# The same pnpm settings as the components' base image (alixea-erp/component-bases), for every process: a shell, an
# AI agent and the editor write one node_modules layout, the one the component installs
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
# In the image, not the home folder: a deployment's home is only filled at its first start, and would keep the pnpm
# of that day
ENV COREPACK_HOME=/usr/local/share/corepack
ENV PNPM_CONFIG_NODE_LINKER=hoisted
ENV PNPM_CONFIG_MINIMUM_RELEASE_AGE=0
ENV PNPM_CONFIG_STRICT_DEP_BUILDS=false
ENV PNPM_CONFIG_CONFIRM_MODULES_PURGE=false

# Install basic build tools
RUN apt-get update \
    && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        make \
        unzip \
        # The tools in this package are used when installing packages for Python
        build-essential \
        # Required for PostgreSQL
        libpq-dev \
        # Required for ts
        moreutils \
        rsync \
        zip \
        jq \
        curl \
        # Required for VS Code SSH remote
        netcat-openbsd \
        # Required for scp support
        openssh-server

# Build tools for native packages, and tools and shells not in the common script
RUN apt-get -y install cmake python3-dev \
    && apt-get install -yq vim vim-doc xtail software-properties-common libsecret-1-dev

# Install and configure supervisord
RUN apt-get install -y supervisor
COPY supervisord.conf /etc/supervisord.conf

# The alixea command runs devpod-cli, whose javascript core mounts into the container at runtime
RUN echo '#!/bin/bash' > /usr/local/bin/alixea \
    && echo 'bun /usr/local/lib/alixea-cli/alixea.js "$@"' >> /usr/local/bin/alixea \
    && chmod +x /usr/local/bin/alixea


# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

CMD [ "supervisord", "-c", "/etc/supervisord.conf" ]
