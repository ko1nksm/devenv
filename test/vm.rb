config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(vmname)}
  load config
  provide system
  provide upgrade
  provide packages
  provide samba #{NETWORK}
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
