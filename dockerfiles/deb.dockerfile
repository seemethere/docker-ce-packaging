ARG BASE=ubuntu
ARG BUILD_IMAGE=ubuntu:bionic
ARG GOLANG_IMAGE=golang:latest

FROM ${GOLANG_IMAGE} as golang

# There's no real difference between ubuntu/(deb|rasp)bian
# but lets leave the door open if there are actually
# differences later on

FROM ${BUILD_IMAGE:-ubuntu:latest} as ubuntu-base

FROM ${BUILD_IMAGE:-debian:latest} as debian-base

FROM ${BUILD_IMAGE:-resin/rpi-raspbian:latest} as raspbian-base

FROM ${BASE}-base as builder

# debian epoch, use if the versioning scheme has changed and new packages
# will no longer be recognized as newer
ENV EPOCH 5

RUN apt-get update && apt-get install -y \
        curl \
        devscripts \
        equivs \
        git
COPY --from=golang /usr/local/go /usr/local/go/
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

ARG COMMON_FILES=cli/debian
ENV COMMON_FILES ${COMMON_FILES}
COPY ${COMMON_FILES} /root/build-deb/debian
RUN mk-build-deps \
        -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" \
        -i /root/build-deb/debian/control

# Copy our sources and untar them
COPY sources/ /sources
RUN mkdir -p /go/src/github.com/docker/ && \
        tar -xzf /sources/*.tgz -C /go/src/github.com/docker/

RUN ln -snf /go/src/github.com/docker/cli /root/build-deb/cli
RUN ln -snf /go/src/github.com/docker/docker /root/build-deb/engine

COPY --from=golang /usr/local/go /usr/local/go

COPY scripts/build-deb /root/build-deb/build-deb
COPY scripts/gen-deb-ver /root/build-deb/gen-deb-ver

WORKDIR /root/build-deb
ENTRYPOINT ["/root/build-deb/build-deb"]
