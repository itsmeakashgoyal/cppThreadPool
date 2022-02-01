FROM ubuntu:18.04
LABEL Description="Build environment for cppThreadPool"

ENV HOME /root
SHELL ["/bin/bash", "-c"]

# Copy the current folder which contains C++ source code to the Docker image under /usr/src
COPY . /usr/src

# Specify the working directory
WORKDIR /usr/src

# Install packages in docker container
RUN apt-get update && apt-get -y --no-install-recommends install \
	build-essential \
	clang \
	cmake \
	gdb \
	wget


