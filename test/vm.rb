config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  include config
  provide system
  provide upgrade
  provide packages
  provide samba #{$NETWORK}
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
