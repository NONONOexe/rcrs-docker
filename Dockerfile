# base
FROM ubuntu:22.04 AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    git \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# rcrs-server
FROM base AS server
WORKDIR /app
RUN git clone https://github.com/roborescue/rcrs-server.git
WORKDIR /app/rcrs-server
RUN ./gradlew --no-daemon completeBuild

# rcrs-agent
FROM base AS agent
WORKDIR /app/rcrs-agent

# ringo-viewer
FROM ubuntu:22.04 AS ringo
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    p7zip-full \
    ca-certificates \
    && \
    curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git clone https://github.com/ringo-ringo-ringo/ringo-viewer.git
WORKDIR /app/ringo-viewer
RUN cp .env.example .env
RUN npm install
EXPOSE 3000
