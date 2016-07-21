config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  include config
  provide system
  provide packages
  provide docker-tools
  provide samba #{$NETWORK}
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
