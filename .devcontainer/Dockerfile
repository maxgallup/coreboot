FROM coreboot/coreboot-sdk:latest

# ENV DEBIAN_FRONTEND=noninteractive

# RUN apt-get update && \
#     apt-get install -y curl \
#         sudo \
#         nano \
#         git \
#         software-properties-common \
#         build-essential \
#         gcc-aarch64-linux-gnu \
#         gcc-arm-linux-gnueabihf \
#         pkg-config

# This is to ensure that the host where the docker container is built has the same uid/gid
# as the user used inside the container. Otherwise, permission issues.
# ARG HOST_UID

# RUN echo 'root:dev' | chpasswd
# RUN useradd -u ${HOST_UID} -ms /bin/bash dev && echo 'dev:dev' | chpasswd && adduser dev sudo
# RUN echo 'dev ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# COPY --chown=dev:dev .devcontainer/scripts/gu /usr/local/bin/gu
# COPY --chown=dev:dev .devcontainer/scripts/.bashrc /home/dev/.bashrc

# USER dev

# # Rust Install
# RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Typst Install
# RUN /home/dev/.cargo/bin/cargo install --git https://github.com/typst/typst --locked typst-cli

