# base
FROM ubuntu:22.04 AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    git \
    dos2unix && \
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
