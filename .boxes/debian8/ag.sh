#!/bin/sh

# https://github.com/ggreer/the_silver_searcher/releases
AG_VERSION=0.31.0
if [ ! -e /usr/local/src/the_silver_searcher-${AG_VERSION} ]; then
    curl -sSL https://github.com/ggreer/the_silver_searcher/archive/${AG_VERSION}.tar.gz | tar zx -C /usr/local/src
fi
cd /usr/local/src/the_silver_searcher-${AG_VERSION}
./build.sh
make install
