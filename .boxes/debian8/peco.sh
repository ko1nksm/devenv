#!/bin/sh

# https://github.com/peco/peco/releases/
PECO_VERSION=v0.3.6
curl -sSL https://github.com/peco/peco/releases/download/$PECO_VERSION/peco_linux_amd64.tar.gz | tar zx -C /usr/local/src
install -m 755 /usr/local/src/peco_linux_amd64/peco /usr/local/bin
