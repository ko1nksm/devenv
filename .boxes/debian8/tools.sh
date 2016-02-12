#!/bin/sh

# https://github.com/ggreer/the_silver_searcher/releases
AG_VERSION=0.31.0
if [ ! -e /usr/local/src/the_silver_searcher-${AG_VERSION} ]; then
    curl -sSL https://github.com/ggreer/the_silver_searcher/archive/${AG_VERSION}.tar.gz | tar zx -C /usr/local/src
fi
cd /usr/local/src/the_silver_searcher-${AG_VERSION}
./build.sh
make install

# https://github.com/peco/peco/releases/
PECO_VERSION=v0.3.5
curl -sSL https://github.com/peco/peco/releases/download/$PECO_VERSION/peco_linux_amd64.tar.gz | tar zx -C /usr/local/src
install -m 755 /usr/local/src/peco_linux_amd64/peco /usr/local/bin
