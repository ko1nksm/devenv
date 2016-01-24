config.vm.network "private_network", ip: '192.168.33.9'

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(vmname)}
  provide 10config
  provide 20initialize
  provide 21upgrade
  provide 22base-packages
  provide 31samba '192.168.33.'
  provide 41samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE}
SHELL
