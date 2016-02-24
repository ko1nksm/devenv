#!/bin/sh

set -e

apt-get install -y \
  zsh bash-completion lv vim vim-doc nano- wget curl dnsutils jq \
  apt-transport-https bridge-utils samba

apt-get install -y \
  build-essential automake gettext re2c pkg-config libxml2-dev libssl-dev \
  libbz2-dev libsqlite3-dev libpng12-dev libjpeg-dev libmcrypt-dev \
  libtidy-dev libxslt1-dev libpcre3-dev liblzma-dev unixodbc-dev \
  libcurl4-openssl-dev libexpat1-dev libncurses5-dev libncursesw5-dev \
  tk8.6 libreadline-dev libreadline5-
