# This is ripped from <https://hub.docker.com/r/langrisha/keybase/dockerfile>,
# where the repo was last updated "3 years ago"
#
# I've made it more ugly.

ARG KEYBASE_DEB_URL=https://prerelease.keybase.io/keybase_amd64.deb
ARG KEYBASE_DEBSIG_URL=https://prerelease.keybase.io/keybase_amd64.deb.sig

FROM buildpack-deps:eoan-curl
ARG KEYBASE_DEB_URL
ARG KEYBASE_DEBSIG_URL

LABEL maintainer="Phil Pennock <noc+keybase-docker@pennock-tech.com>"

COPY code_signing_key.asc /tmp/

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

RUN true \
	&& apt-get install -f -y \
	&& groupadd -g 1000 keybase \
	&& useradd --create-home -g keybase -u 1000 keybase \
	&& rm -r /var/lib/apt/lists/* \
	&& rm keybase_amd64.deb* /tmp/code_signing_key.asc \
	&& rm -rf /root/.gnupg

USER keybase
WORKDIR /home/keybase
CMD ["bash"]

RUN run_keybase
