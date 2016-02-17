config.vm.provider :virtualbox do |vb|
  vb.attach_storage "docker-data.vdi", **{
    storagectl: 'SATA Controller',
    port: 2,
    device: 0,
    type: 'hdd',
    size: 10240,
    basedir: $STORAGE_DIR,
  }
end

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  load config
  create-partition /dev/sdc
  service docker stop
  mount-partition DOCKER /dev/sdc1 /var/lib/docker
  service docker start
  provide system
  provide upgrade
  provide packages
  provide docker-tools
  provide docker-config
  provide nsupdate #{$IPADDR_LIST["dns"]}
  provide samba #{$NETWORK}
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
