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
  create-partition "/dev/sdc"
  mount-partition "DOCKER", "/dev/sdc1" "/var/lib/docker"
  provide 10config
  provide 20initialize
  provide 21upgrade
  provide 22base-packages
  provide 30tools
  provide 31docker
  provide 31samba '192.168.33.'
  provide 40user-config #{USERNAME}
  provide 41samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE}
SHELL
