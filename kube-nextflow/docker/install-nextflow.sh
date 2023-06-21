#!/bin/bash

curl -s "https://get.sdkman.io" | bash
source "/root/.sdkman/bin/sdkman-init.sh" && sdk install java 17.0.6-amzn
cd /usr/bin
wget -qO- "https://get.nextflow.io" | bash
