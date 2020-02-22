# This is ripped from <https://hub.docker.com/r/langrisha/keybase/dockerfile>,
# where the repo was last updated "3 years ago"
#
# I've made it more ugly.

ARG KEYBASE_DEB_URL=https://prerelease.keybase.io/keybase_amd64.deb
ARG KEYBASE_DEBSIG_URL=https://prerelease.keybase.io/keybase_amd64.deb.sig

# We use -scm to get the git command because we install git-remote-keybase and
# want to be able to use it.
FROM buildpack-deps:eoan-scm AS root
ARG KEYBASE_DEB_URL
ARG KEYBASE_DEBSIG_URL

LABEL maintainer="Phil Pennock <noc+keybase-docker@pennock-tech.com>"

COPY code_signing_key.asc /tmp/

# Breaks apart into a few steps; it's less efficient in the final image,
# but it lets me iterate and debug with better caching.

RUN true \
	&& apt-get update && apt-get install -y \
		fuse \
		libappindicator1 \
		--no-install-recommends \
	&& gpg --import /tmp/code_signing_key.asc

RUN true \
	&& curl -Lo keybase_amd64.deb ${KEYBASE_DEB_URL} \
	&& curl -Lo keybase_amd64.deb.sig ${KEYBASE_DEBSIG_URL} \
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
	&& groupadd -g 1000 keybase \
	&& useradd --create-home -g keybase -u 1000 keybase \
	&& mkdir -pv -m 0700 /run/user/1000 && chown keybase:keybase /run/user/1000 \
	&& rm -r /var/lib/apt/lists/* \
	&& rm keybase_amd64.deb* /tmp/code_signing_key.asc \
	&& rm -rf /root/.gnupg

COPY keybase.is-up-to-date /usr/local/bin/./

VOLUME /home/keybase

FROM root

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

ENV XDG_RUNTIME_DIR /run/user/1000

CMD ["bash"]

RUN run_keybase
