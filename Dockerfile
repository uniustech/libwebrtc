FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    build-essential libglib2.0-dev libgtk2.0-dev libxtst-dev \
    libxss-dev libpci-dev libdbus-1-dev \
    libnss3-dev libasound2-dev libpulse-dev \
    libudev-dev wget ca-certificates libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
    git cmake ninja-build && \
    rm -rf /var/lib/apt/lists/*

# Install Python 2.7 from source
RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz && \
    tar xzf Python-2.7.18.tgz && \
    cd Python-2.7.18 && \
    ./configure && \
    make -j && \
    make altinstall && \
    cd .. && \
    rm -rf Python-2.7.18* && \
    ln -sf /usr/local/bin/python2.7 /usr/bin/python

RUN git clone https://github.com/uniustech/libwebrtc /opt/libwebrtc && \
    cd /opt/libwebrtc && \
    mkdir out && \
    cd out && \
    cmake .. && \
    make -j && \
    make install
