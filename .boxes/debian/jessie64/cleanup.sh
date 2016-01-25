#!/bin/sh

echo '\033[1;33mCleanup\033[0;39m'
echo -n '\033[0;33m'

old_kernels=$(dpkg -l | egrep 'linux-(image|headers)-[0-9]' | grep -v $(uname -r | sed s/-amd64//) | awk '{print $2}')

if [ "$old_kernels" ]; then
  apt-get -y purge $old_kernels
  apt-get -y autoremove
  apt-get clean
fi

ln -s -f /dev/null /etc/udev/rules.d/70-persistent-net.rules

dd if=/dev/zero of=/zero bs=1MiB
rm /zero

echo -n '\033[0;39m'
