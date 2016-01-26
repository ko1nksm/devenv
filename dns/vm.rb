config.vm.network "private_network", ip: '192.168.33.12'

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(vmname)}
  provide system
  provide upgrade
  provide packages
  provide docker-tools #{USERNAME}
  provide samba '192.168.33.'
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
