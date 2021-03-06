#!/bin/sh

set -e

GIT_VERSION=2.9.2
TIG_VERSION=tig-2.1.1

MAX_JOBS=$(($(nproc) * 2))

# https://github.com/git/git/releases
if [ ! -e /usr/local/src/git-${GIT_VERSION} ]; then
  curl -sSL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz | tar zx -C /usr/local/src
fi
cd /usr/local/src/git-${GIT_VERSION}
make -j $MAX_JOBS prefix=/usr/local
make install prefix=/usr/local

curl -sSL https://www.kernel.org/pub/software/scm/git/git-manpages-${GIT_VERSION}.tar.gz | tar zx -C /usr/local/share/man/
cp -a /usr/local/src/git-${GIT_VERSION}/contrib /usr/local/share/git-core/
chown -R root:staff /usr/local/share/man
find /usr/local/share/man -type d -exec chmod u=rwx,g=rwxs,o=rx {} \;
find /usr/local/share/man -type f -exec chmod 444 {} \;
find /usr/local/bin -type d -exec chmod u=rwx,g=rwxs,o=rx {} \;
find /usr/local/libexec -type d -exec chmod u=rwx,g=rwxs,o=rx {} \;
chown -R root:staff /usr/local/share/git-core


# https://github.com/jonas/tig/releases
TIG_DIR=/usr/local/src/tig
if [ ! -e $TIG_DIR ]; then
  git clone https://github.com/jonas/tig.git $TIG_DIR
else
  cd $TIG_DIR && git fetch
fi
cd $TIG_DIR
git checkout $TIG_VERSION
./autogen.sh
LIBS=-lncursesw ./configure
make -j $MAX_JOBS prefix=/usr/local
make install prefix=/usr/local
