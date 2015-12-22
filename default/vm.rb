config.vm.network "private_network", ip: '192.168.33.10'

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(vmname)}
  provide 10config
  provide 20initialize
  provide 21upgrade
  provide 22base-packages
  provide 24build-packages
  provide 30tools
  provide 31git
  provide 31docker
  provide 31samba '192.168.33.'
  provide 40user-config #{USERNAME}
  provide 41samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
SHELL
