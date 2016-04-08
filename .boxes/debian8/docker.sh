#!/bin/sh

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

cat <<DATA > /etc/apt/apt.conf.d/docker
Acquire::HTTP::Proxy::apt.dockerproject.org "DIRECT";
DATA

cat <<DATA > /etc/apt/sources.list.d/docker.list
deb https://apt.dockerproject.org/repo debian-jessie main
DATA

apt-get -y update
apt-get -y install docker-engine
service docker stop
rm -rf /var/lib/docker/aufs


mkdir -p /etc/systemd/system/docker.service.d
cat <<DATA > /etc/systemd/system/docker.service.d/docker.conf
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --storage-driver=overlay
DATA
systemctl daemon-reload
