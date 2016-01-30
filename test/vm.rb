config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  load config
  provide system #{USERNAME}
  provide upgrade
  provide packages
  provide samba #{$NETWORK}
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
