config.vm.provider :virtualbox do |vb|
  vb.cpus = 1
  vb.memory = 256
end

config.vm.network "forwarded_port", guest: 3128, host: 3128

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  include config
  provide system
  provide samba disable
  provide squid
  #{COMPLETE()}
SHELL
