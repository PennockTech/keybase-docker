# This is ripped from <https://hub.docker.com/r/langrisha/keybase/dockerfile>,
# where the repo was last updated "3 years ago"
#
# I've made it more ugly.

ARG KEYBASE_LINUX_VERSIONS_URL=http://prerelease.keybase.io.s3.amazonaws.com/update-linux-prod.json
ARG KEYBASE_DEB_BASEURL=https://s3.amazonaws.com/prerelease.keybase.io/linux_binaries/deb/
ARG KEYBASE_DEB_ARCH=amd64

ARG KEYBASE_UID=1000

# We use -scm to get the git command because we install git-remote-keybase and
# want to be able to use it.
FROM buildpack-deps:focal-scm AS root
ARG KEYBASE_LINUX_VERSIONS_URL
ARG KEYBASE_DEB_BASEURL
ARG KEYBASE_DEB_ARCH
ARG KEYBASE_UID

LABEL maintainer="Phil Pennock <noc+keybase-docker@pennock-tech.com>"

COPY code_signing_key.asc /tmp/

# Breaks apart into a few steps; it's less efficient in the final image,
# but it lets me iterate and debug with better caching.

RUN true \
	&& apt-get update && apt-get install -y \
		fuse \
		libappindicator1 \
		jq \
		--no-install-recommends \
	&& gpg --import /tmp/code_signing_key.asc

# Beware that /bin/sh is dash which doesn't support ${current_version//+/.}
RUN true \
	&& current_version="$(curl -fSs "${KEYBASE_LINUX_VERSIONS_URL}" | jq -r .version)" \
	&& fnv="$(printf '%s\n' "$current_version" | tr + .)" \
	&& rfu="${KEYBASE_DEB_BASEURL}keybase_${fnv}_${KEYBASE_DEB_ARCH}.deb" \
	&& printf 'URL: <%s>\n' "$rfu" \
	&& curl -Lo keybase_amd64.deb "$rfu" \
	&& curl -Lo keybase_amd64.deb.sig "$rfu.sig" \
	&& gpg --verify keybase_amd64.deb.sig keybase_amd64.deb \
	&& { dpkg -i keybase_amd64.deb || true ; }

# Fix any missing dependencies.
RUN true \
	&& apt-get install -f -y

# Additional convenience packages for me, when inside the container.
# NB: jq is needed for keybase.is-up-to-date, so keep at least that.
RUN true \
	&& apt-get install -y zsh less vim-tiny tree jq silversearcher-ag

RUN true \
	&& groupadd -g ${KEYBASE_UID} keybase \
	&& useradd --create-home -g keybase -u ${KEYBASE_UID} keybase \
	&& mkdir -pv -m 0700 /run/user/${KEYBASE_UID} && chown keybase:keybase /run/user/${KEYBASE_UID} \
	&& rm -r /var/lib/apt/lists/* \
	&& rm keybase_amd64.deb* /tmp/code_signing_key.asc \
	&& rm -rf /root/.gnupg

COPY keybase.is-up-to-date /usr/local/bin/./

VOLUME /home/keybase

FROM root
ARG KEYBASE_UID

USER keybase
WORKDIR /home/keybase

# We expect $HOME to be bind-mounted in from an external volume, providing persistence
# for the device registration.  As such, the default ~/.config/keybase/kbfs
# FUSE mount interacts ... "poorly".
# So we plumb up XDG_RUNTIME_DIR in the normal modern pattern, and then scratch our heads
# at how Keybase invent the shiny new XDG_RUNTIME_USER variable, and ... figure out something.
# Ah, <https://keybase.io/docs/the_app/install_linux> is wrong, XDG_RUNTIME_USER does not appear
# in the tree of code at <https://github.com/keybase/client>.
# And in fact XDG_RUNTIME_DIR is ignored in favor of $(keybase config get -b mountdir)

ENV XDG_RUNTIME_DIR /run/user/${KEYBASE_UID}

CMD ["bash"]

RUN run_keybase
