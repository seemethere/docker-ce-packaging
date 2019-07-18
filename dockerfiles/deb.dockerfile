ARG BUILD_IMAGE=ubuntu:bionic
# Install golang since the package managed one probably is too old and ppa's don't cover all distros
ARG GOLANG_IMAGE
FROM ${GOLANG_IMAGE} as golang

FROM ${BUILD_IMAGE}
RUN cat /etc/os-release
# Install some pre-reqs
RUN apt-get update && apt-get install -y \
        curl \
        devscripts \
        equivs \
        git \
        lsb-release
ENV GOPATH /go
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
ENV GO_SRC_PATH /go/src/${IMPORT_PATH}

COPY --from=source /source /source

# Set up debian packaging files
RUN mkdir -p /root/package
COPY debian/ /root/package/debian
COPY common /root/common
WORKDIR /root/package

COPY --from=golang /usr/local/go /usr/local/go/

# Install all of our build dependencies, if any
RUN mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i debian/control

# Copy over our entrypoint
COPY scripts/build-deb /build-deb
COPY scripts/.helpers /.helpers

ENTRYPOINT ["/build-deb"]
