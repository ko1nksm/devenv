config.vm.box = "centos7"

config.vm.provider :virtualbox do |vb|
  vb.cpus = 1
  vb.customize ["modifyvm", :id, "--nictype1", "82540EM" ]
  vb.customize ["modifyvm", :id, "--nictype2", "82540EM" ]
end

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  #{COMPLETE()}
SHELL
