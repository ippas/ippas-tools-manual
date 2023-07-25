# Use an official Ubuntu 22.04 as a parent image
FROM ubuntu:22.04

# Set default shell
SHELL ["/bin/bash", "-c"]

# Avoid timezone interactive dialog
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install necessary software
RUN apt-get update && \
    apt-get install -y screen \
                       wget \
                       curl \
                       unzip \
                       zip \
                       git \
                       neovim

# Set default shell for screen
RUN echo "shell /bin/bash" > ~/.screenrc

# Install Java through SDKMAN! and nextflow
RUN curl -s "https://get.sdkman.io" | bash && \
    source "/root/.sdkman/bin/sdkman-init.sh" && \
    sdk install java 17.0.6-amzn && \
    cd /usr/bin && \
    wget -qO- "https://get.nextflow.io" | bash

ENV NXF_EXECUTOR k8s 
ENV NXF_WORK /workspace/nxf_work
ENV NXF_ASSETS /workspace/nxf_assets
COPY nextflow.config /

# Set up the alias to run screen in UTF-8 mode
RUN echo "alias screen='screen -U'" >> ~/.bashrc

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set default command
CMD ["bash"]
