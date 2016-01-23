#!/bin/sh

set -eu

name=$1

cd $(dirname $0)/$name

if vagrant box list | grep "$name (virtualbox, 0)" >/dev/null; then
  echo "Found updated box"
  export LATEST_BOX_VERSION=0
fi
vagrant halt
vagrant up --provision
vagrant halt
vagrant package
if [ -f package.box ]; then
  vagrant box add package.box --name "$name" --force
  rm package.box
  vagrant destroy --force
else
  echo "Not found package.box"
fi
