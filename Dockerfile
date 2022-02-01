FROM ubuntu:18.04
LABEL Description="Build environment for cppThreadPool"

ENV HOME /root
SHELL ["/bin/bash", "-c"]
COPY ./installdeps.sh /installdeps.sh

# install all dependencies in docker image
RUN chmod +x /installdeps.sh && \
    /bin/bash -c "/installdeps.sh" && \
    apt-get clean && \
    apt-get autoclean
