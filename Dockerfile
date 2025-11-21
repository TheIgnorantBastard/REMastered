# REMastered tooling container
# Base image supplies PowerShell 7 on Ubuntu; we add dosbox-x and helper tools.
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       dosbox-x \
       git \
       python3 python3-pip \
       unzip \
       ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Default entry drops you into pwsh so you can run Start-GameProject or other scripts.
ENTRYPOINT ["pwsh"]
