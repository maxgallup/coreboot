FROM coreboot/coreboot-sdk:latest

USER root
RUN echo 'root:root' | chpasswd

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl sudo gcc-multilib

RUN echo 'coreboot:coreboot' | chpasswd

RUN adduser coreboot sudo ; echo 'coreboot ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER coreboot
