ARG BUILD_IMAGE=centos:7
ARG BASE=centos

# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GO_IMAGE=golang:latest
FROM ${GO_IMAGE} as golang

FROM alpine:3.8 as source-base
RUN apk -U --no-cache add git

FROM source-base as engine-source
ARG ENGINE_REF=master
RUN git clone https://github.com/docker/engine /engine
RUN git -C /engine checkout ${ENGINE_REF}

FROM source-base as cli-source
ARG CLI_REF=master
RUN git clone https://github.com/docker/cli /cli
RUN git -C /cli checkout ${CLI_REF}

FROM ${BUILD_IMAGE} as centos-base
RUN yum install -y rpm-build git
# Overwrite repo that was failing on aarch64
RUN sed -i 's/altarch/centos/g' /etc/yum.repos.d/CentOS-Sources.repo

FROM ${BUILD_IMAGE} as fedora-base
RUN dnf install -y rpm-build git dnf-plugins-core

FROM ${BUILD_IMAGE} as suse-base
# On older versions of Docker the path may not be explicitly set
# opensuse also does not set a default path in their docker images
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
RUN zypper install -y git rpm rpm-build
RUN echo "%_topdir    /root/rpmbuild" > /root/.rpmmacros

FROM suse-base as opensuse-leap-base

FROM ${BUILD_IMAGE} as amzn-base
RUN yum install -y yum-utils rpm-build git

FROM ${BASE}-base
COPY --from=golang /usr/local/go /usr/local/go/
ENV GOPATH /go
ENV PATH "$PATH:/usr/local/go/bin:$GOPATH/bin"
RUN go get github.com/cpuguy83/go-md2man

COPY common/ /root/rpmbuild/SOURCES/
COPY rpm/*.spec /root/rpmbuild/SPECS/
COPY scripts/build-rpm /build-rpm
COPY scripts/.rpm-helpers /.rpm-helpers

RUN mkdir -p /go
COPY --from=engine-source /engine /go/src/github.com/docker/docker
COPY --from=cli-source    /cli    /go/src/github.com/docker/cli

WORKDIR /root/rpmbuild
ENTRYPOINT ["/build-rpm"]
