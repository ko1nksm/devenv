config.vm.provider :virtualbox do |vb|
  vb.cpus = 1
  vb.memory = 320
end

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  include config
  provide system
  provide samba disable
  provide devdns #{$IPADDR_LIST[name]} --zone dev.int
  #{COMPLETE()}
SHELL
