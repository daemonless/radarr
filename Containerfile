ARG BASE_VERSION=15
FROM ghcr.io/daemonless/arr-base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="radarr"
ARG RADARR_BRANCH="master"
ARG UPSTREAM_URL="https://radarr.servarr.com/v1/update/master/changes?os=bsd&runtime=netcore"
ARG UPSTREAM_JQ=".[0].version"
ARG HEALTHCHECK_ENDPOINT="http://localhost:7878/ping"

ENV HEALTHCHECK_URL="${HEALTHCHECK_ENDPOINT}"

LABEL org.opencontainers.image.title="Radarr" \
    org.opencontainers.image.description="Radarr movie management on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/radarr" \
    org.opencontainers.image.url="https://radarr.video/" \
    org.opencontainers.image.documentation="https://wiki.servarr.com/radarr" \
    org.opencontainers.image.licenses="GPL-3.0-only" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="7878" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.volumes="/movies,/downloads" \
    org.freebsd.jail.allow.mlock="required" \
    io.daemonless.category="Media Management" \
    io.daemonless.upstream-url="${UPSTREAM_URL}" \
    io.daemonless.upstream-jq="${UPSTREAM_JQ}" \
    io.daemonless.healthcheck-url="${HEALTHCHECK_ENDPOINT}" \
    io.daemonless.packages="${PACKAGES}"

# Install Radarr from FreeBSD packages
RUN pkg update && \
    pkg install -y ${PACKAGES} && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Download and install Radarr
RUN mkdir -p /usr/local/share/radarr /config && \
    RADARR_VERSION=$(fetch -qo - "https://radarr.servarr.com/v1/update/${RADARR_BRANCH}/changes?os=bsd&runtime=netcore" | \
    grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4) && \
    fetch -qo - "https://radarr.servarr.com/v1/update/${RADARR_BRANCH}/updatefile?os=bsd&arch=x64&runtime=netcore" | \
    tar xzf - -C /usr/local/share/radarr --strip-components=1 && \
    rm -rf /usr/local/share/radarr/Radarr.Update && \
    chmod +x /usr/local/share/radarr/Radarr && \
    chmod -R o+rX /usr/local/share/radarr && \
    printf "UpdateMethod=docker\nBranch=${RADARR_BRANCH}\nPackageVersion=%s\nPackageAuthor=[daemonless](https://github.com/daemonless/daemonless)\n" "$RADARR_VERSION" > /usr/local/share/radarr/package_info && \
    mkdir -p /app && echo "$RADARR_VERSION" > /app/version && \
    chown -R bsd:bsd /usr/local/share/radarr /config

# Copy service definition and init scripts
COPY root/ /

# Make scripts executable
RUN chmod +x /etc/services.d/radarr/run /etc/cont-init.d/* 2>/dev/null || true


EXPOSE 7878
VOLUME /config


