config.vm.provider :virtualbox do |vb|
  vb.cpus = 1
  vb.memory = 512
end

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  load config
  provide system
  provide upgrade
  provide packages
  provide docker-tools #{USERNAME}
  provide samba #{$NETWORK}
  provide devdns #{$IPADDR_LIST[name]} --zone local --zone dev
  provide samba-export #{USERNAME} ~#{USERNAME} #{USERNAME}
  #{COMPLETE()}
SHELL
