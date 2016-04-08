#!/bin/sh

set -e

JO_VERSION=1.0

# https://github.com/jpmens/jo/releases
if [ ! -e /usr/local/src/jo-${JO_VERSION} ]; then
  curl -sSL https://github.com/jpmens/jo/releases/download/v${JO_VERSION}/jo-${JO_VERSION}.tar.gz | tar zx -C /usr/local/src
fi
cd /usr/local/src/jo-${JO_VERSION}
autoreconf -i
./configure
make
make install
