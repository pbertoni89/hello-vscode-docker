# Author: [BG] p.bertoni@r4p.it

FROM debian:bookworm

# Set non-interactive frontend for package installation
ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.13.15
ARG GCC_VERSION=12

# Install Python and C++ build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        g++-${GCC_VERSION} \
        gcc-${GCC_VERSION} \
        git \
        libffi-dev \
        libbz2-dev \
        liblzma-dev \
        libssl-dev \
        libxml++2.6-dev \
        pkg-config \
        xz-utils \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ENV CC=gcc-${GCC_VERSION} \
    CXX=g++-${GCC_VERSION}

# Install a specific Python version from source
ADD https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz Python-${PYTHON_VERSION}.tar.xz
RUN tar xf Python-${PYTHON_VERSION}.tar.xz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && \
    rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tar.xz

# Copy the requirements file into the container
COPY requirements.txt /tmp/requirements.txt

ENV VIRTUAL_ENV=/opt/venv

# Create the virtual environment and install dependencies from the file
RUN python${PYTHON_VERSION%.*} -m venv "${VIRTUAL_ENV}" && \
    "${VIRTUAL_ENV}/bin/python" -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Set environment to use the virtual environment by default
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

WORKDIR /workspace
