# Use an official Ubuntu 22.04 as a parent image
FROM ubuntu:22.04

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

# Install Java through SDKMAN! and nextflow
COPY install-nextflow.sh /
RUN chmod +x /install-nextflow.sh
RUN /install-nextflow.sh
ENV NXF_EXECUTOR k8s 
ENV NXF_WORK /workspace/nxf_work
ENV NXF_ASSETS /workspace/nxf_assets

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm /install-nextflow.sh

# Set default command
CMD ["bash"]
