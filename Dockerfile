FROM ubuntu:22.04
LABEL maintainer="oaude1@ocdsb.ca"
ARG DEBIAN_FRONTEND=noninteractive


# Avoid "delaying package configuration, since apt-utils is not installed"
RUN apt update && apt install --yes apt-utils


# Environment
RUN apt update && \
    apt install --yes locales && \
    locale-gen "en_US.UTF-8" && dpkg-reconfigure locales


# Unminimize system
RUN yes | unminimize


# Install curl 
RUN apt update && \
    apt install --yes curl

# Install Node.js 19.x
# https://nodejs.dev/en/download/
# https://github.com/tj/n#installation
RUN curl --location https://raw.githubusercontent.com/tj/n/master/bin/n --output /usr/local/bin/n && \
    chmod a+x /usr/local/bin/n && \
    n 19.8.1


# Suggested build environment for Python, per pyenv, even though we're building ourselves
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
RUN apt update && \
    apt install --no-install-recommends --yes \
        make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev llvm ca-certificates curl wget unzip \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install Python 3.11.x
# https://www.python.org/downloads/
RUN cd /tmp && \
    curl https://www.python.org/ftp/python/3.11.3/Python-3.11.3.tgz --output Python-3.11.3.tgz && \
    tar xzf Python-3.11.3.tgz && \
    rm --force Python-3.11.3.tgz && \
    cd Python-3.11.3 && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm --force --recursive Python-3.11.3 && \
    ln --relative --symbolic /usr/local/bin/pip3 /usr/local/bin/pip && \
    ln --relative --symbolic /usr/local/bin/python3 /usr/local/bin/python && \
    pip3 install --upgrade pip

# Install SQLite 3.x
# https://www.sqlite.org/download.html
# https://www.sqlite.org/howtocompile.html#compiling_the_command_line_interface
RUN cd /tmp && \
    curl -O https://www.sqlite.org/2022/sqlite-amalgamation-3400100.zip && \
    unzip sqlite-amalgamation-3400100.zip && \
    rm --force sqlite-amalgamation-3400100.zip && \
    cd sqlite-amalgamation-3400100 && \
    gcc -DHAVE_READLINE shell.c sqlite3.c -lpthread -ldl -lm -lreadline -lncurses -o /usr/local/bin/sqlite3 && \
    cd .. && \
    rm --force --recursive sqlite-amalgamation-3400100

# Install GitHub CLI
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install gh --yes

# Install Ubuntu packages
RUN apt update && \
    apt install --no-install-recommends --yes \
        astyle \
        bash-completion \
        clang \
        coreutils `# for fold` \
        cowsay \
        dos2unix \
        dnsutils `# For nslookup` \
        fonts-noto-color-emoji `# For terminal` \
        gdb \
        git \
        git-lfs \
        jq \
        less \
        make \
        man \
        man-db \
        nano \
        openssh-client `# For ssh-keygen` \
        psmisc `# For fuser` \
        sudo \
        tzdata `# For TZ` \
        valgrind \
        vim \
        zip


# Install Node.js packages
RUN npm install -g http-server


# Install Python packages
RUN pip3 install \
        matplotlib \
        pandas \
        Pillow \
        scipy \
        scikit-learn \
        pytest

# Temporary fix for "libssl.so.1.1: cannot open shared object file: No such file or directory" on Ubuntu 22.04
# https://stackoverflow.com/questions/72133316/ubuntu-22-04-libssl-so-1-1-cannot-open-shared-object-file-no-such-file-or-di
RUN cd /tmp && \
    curl -O http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.17_amd64.deb && \
    curl -O http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.17_arm64.deb && \
    (dpkg -i libssl1.1_1.1.1f-1ubuntu2.17_amd64.deb || dpkg -i libssl1.1_1.1.1f-1ubuntu2.17_arm64.deb) && \
    rm -rf libssl1.1_1.1.1f-1ubuntu2.17*

# Disable bracketed paste
# https://bugs.launchpad.net/ubuntu/+source/bash/+bug/1926256
RUN echo >> /etc/inputrc && \
    echo "# Disable bracketed paste" >> /etc/inputrc && \
    echo "set enable-bracketed-paste off" >> /etc/inputrc


# Add user
RUN useradd --home-dir /home/ubuntu --shell /bin/bash ubuntu && \
    umask 0077 && \
    mkdir -p /home/ubuntu && \
    chown -R ubuntu:ubuntu /home/ubuntu


# Add user to sudoers
RUN echo "\n# CS50 CLI" >> /etc/sudoers && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "Defaults umask_override" >> /etc/sudoers && \
    echo "Defaults umask=0022" >> /etc/sudoers && \
    sed -e "s/^Defaults\tsecure_path=.*/Defaults\t!secure_path/" -i /etc/sudoers

# Copy utility scripts
COPY ./usr /usr

# Version the image (and any descendants)
ARG VCS_REF
RUN echo "$VCS_REF" > /etc/issue
ONBUILD USER root
ONBUILD ARG VCS_REF
ONBUILD RUN echo "$VCS_REF" >> /etc/issue
ONBUILD USER ubuntu


# Set user
USER ubuntu
WORKDIR /home/ubuntu
ENV WORKDIR=/home/ubuntu
