%global debug_package %{nil}
%global source_path   /go/src/github.com/docker/docker
%global _version      %{getenv:RPM_VERSION}
%global _release      %{getenv:RPM_RELEASE_VERSION}
%global _origversion  %{getenv:VERSION}


Name: docker-ce
Version: %{_version}
Release: %{_release}%{?dist}
Epoch: 3
Source0: docker.service
Source1: docker.socket
Summary: The open-source application container engine
Group: Tools/Docker
License: ASL 2.0
URL: https://www.docker.com
Vendor: Docker
Packager: Docker <support@docker.com>

Requires: docker-ce-cli
Requires: container-selinux >= 2:2.74
Requires: libseccomp >= 2.3
Requires: systemd
Requires: iptables
Requires: libcgroup
Requires: containerd.io >= 1.2.2-3
Requires: tar
Requires: xz

# Resolves: rhbz#1165615
Requires: device-mapper-libs >= 1.02.90-1

BuildRequires: bash
BuildRequires: btrfs-progs-devel
BuildRequires: ca-certificates
BuildRequires: cmake
BuildRequires: device-mapper-devel
BuildRequires: gcc
BuildRequires: git
BuildRequires: glibc-static
BuildRequires: libseccomp-devel
BuildRequires: libselinux-devel
BuildRequires: libtool
BuildRequires: libtool-ltdl-devel
BuildRequires: make
BuildRequires: pkgconfig
BuildRequires: pkgconfig(systemd)
BuildRequires: selinux-policy-devel
BuildRequires: systemd-devel
BuildRequires: tar
BuildRequires: which

# conflicting packages
Conflicts: docker
Conflicts: docker-io
Conflicts: docker-engine-cs
Conflicts: docker-ee

# Obsolete packages
Obsoletes: docker-ce-selinux
Obsoletes: docker-engine-selinux
Obsoletes: docker-engine

%description
Docker is a product for you to build, ship and run any application as a
lightweight container.

Docker containers are both hardware-agnostic and platform-agnostic. This means
they can run anywhere, from your laptop to the largest cloud compute instance and
everything in between - and they don't require you to use a particular
language, framework or packaging system. That makes them great building blocks
for deploying and scaling web apps, databases, and backend services without
depending on a particular stack or provider.

%prep
rm -rf %{_topdir}/BUILD/
# symlink the go source path to our build directory
ln -s %{source_path} %{_topdir}/BUILD
cd %{_topdir}/BUILD/

%build

export DOCKER_GITCOMMIT=$(cd %{source_path} && git rev-parse --short=7 HEAD)

for component in tini "proxy dynamic";do
    TMP_GOPATH="/go" hack/dockerfile/install/install.sh $component
done
VERSION=%{_origversion} PRODUCT=docker hack/make.sh dynbinary

echo '{"platform":"Docker Engine - Community","engine_image":"engine-community-dm","containerd_min_version":"1.2.0-beta.1","runtime":"host_install"}' > %{_topdir}/SOURCES/distribution_based_engine.json

%check
bundles/dynbinary-daemon/dockerd -v

%install
# install daemon binary
install -D -p -m 0755 $(readlink -f bundles/dynbinary-daemon/dockerd) $RPM_BUILD_ROOT/%{_bindir}/dockerd

# install proxy
install -D -p -m 0755 /usr/local/bin/docker-proxy $RPM_BUILD_ROOT/%{_bindir}/docker-proxy

# install tini
install -D -p -m 755 /usr/local/bin/docker-init $RPM_BUILD_ROOT/%{_bindir}/docker-init

# install systemd scripts
install -D -m 0644 %{_topdir}/SOURCES/docker.service $RPM_BUILD_ROOT/%{_unitdir}/docker.service
install -D -m 0644 %{_topdir}/SOURCES/docker.socket $RPM_BUILD_ROOT/%{_unitdir}/docker.socket

# install json for docker engine activate / upgrade
install -D -m 0644 %{_topdir}/SOURCES/distribution_based_engine.json $RPM_BUILD_ROOT/var/lib/docker-engine/distribution_based_engine-ce.json

%files
/%{_bindir}/dockerd
/%{_bindir}/docker-proxy
/%{_bindir}/docker-init
/%{_unitdir}/docker.service
/%{_unitdir}/docker.socket
/var/lib/docker-engine/distribution_based_engine-ce.json

%post
%systemd_post docker.service
if ! getent group docker > /dev/null; then
    groupadd --system docker
fi

%preun
%systemd_preun docker.service

%postun
%systemd_postun_with_restart docker.service

%changelog
