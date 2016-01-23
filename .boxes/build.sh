#!/bin/sh

set -eu

name=$1

workdir=$(dirname $0)/$name
cd $workdir

if [ -f package.box ]; then
  echo -e "\033[0;31m$workdir/package.box already exists.\033[0;39m"
  exit 1
fi

if vagrant box list | grep "$name (virtualbox, 0)" >/dev/null; then
  echo "Found updated box"
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
  echo -e "\033[1;33mGenerated package.box [$(expr $size / 1024 / 1024) MB]\033[0;39m"
  vagrant box add package.box --name "$name" --force
  rm package.box
  vagrant destroy --force
else
  echo "Not found package.box"
fi
