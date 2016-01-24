#!/bin/sh

set -eu

name=$1

workdir=$(dirname $0)/$name
cd $workdir

abort() {
  printf "\033[0;31m%s\033[0;39m\n" "$1"
  exit 1
}

info() {
  printf "\033[1;33m%s\033[0;39m\n" "$1"
}

if [ -f package.box ]; then
  abort "$workdir/package.box already exists."
fi

if vagrant box list | grep "$name (virtualbox, 0)" >/dev/null; then
  info "Found updated box"
  export LATEST_BOX_VERSION=0
fi
vagrant halt
vagrant up --provision
vagrant reload
vagrant ssh -c "sudo sh /cleanup"
vagrant halt
vagrant package
if [ -f package.box ]; then
  size=$(wc -c < package.box)
  info "Generated package.box [$(expr $size / 1024 / 1024) MB]"
  vagrant box add package.box --name "$name" --force
  rm package.box
  vagrant destroy --force
else
  abort "Not found package.box"
fi
