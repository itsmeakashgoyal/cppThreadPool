#!/bin/bash

# This script is used to install and build all the tools needed for building and running this project.
# It is used for building a docker image that is used by CI/CD and may be used in the
# development environment.
# If you prefer working w/o docker at your dev station just run the script with sudo.
# Add any other dependencies here which you require for development environment.
set -e

# Install tools
apt-get update && apt-get -y --no-install-recommends install \
    build-essential \
    clang \
    cmake \
    gdb \
    wget