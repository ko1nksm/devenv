config.vm.network "private_network", ip: '192.168.33.11'

config.vm.provider :virtualbox do |vb|
  vb.attach_storage "docker-data.vdi", **{
    storagectl: 'IDE Controller',
    port: 1,
    device: 0,
    type: 'hdd',
    size: 10240,
    basedir: STORAGE_DIR,
  }
end

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(vmname)}
  load config
  create-partition "/dev/sdc"
  mount-partition "DOCKER", "/dev/sdc1" "/var/lib/docker"
  provide system
  provide upgrade
  provide packages
  provide docker-tools #{USERNAME}
  provide samba '192.168.33.'
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
