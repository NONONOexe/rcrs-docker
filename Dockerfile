# Common base with tools for building
FROM ubuntu:24.04 AS builder-base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git
# Note: We do not remove /var/lib/apt/lists/* here to avoid
# repeated 'apt-get update' in downstream images, which
# would increase network usage.

# Java 17 base for building Java applications
FROM builder-base AS java-builder
RUN apt-get install -y --no-install-recommends openjdk-17-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build the rcrs-server application
FROM java-builder AS server
WORKDIR /app
RUN git clone --depth 1 https://github.com/roborescue/rcrs-server.git
WORKDIR /app/rcrs-server
RUN ./gradlew --no-daemon completeBuild

# rcrs-agent-sample
FROM java-builder AS agent-sample
RUN git clone --depth 1 https://github.com/roborescue/adf-sample-agent-java.git /app/rcrs-agent
WORKDIR /app/rcrs-agent

# rcrs-agent-custom
FROM java-builder AS agent-custom
WORKDIR /app/rcrs-agent

# ringo-viewer
FROM builder-base AS ringo
RUN apt-get install -y --no-install-recommends curl p7zip-full && \
    curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git clone --depth 1 https://github.com/ringo-ringo-ringo/ringo-viewer.git
WORKDIR /app/ringo-viewer
RUN cp .env.example .env
RUN npm install
EXPOSE 3000
