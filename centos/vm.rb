config.vm.box = "centos7"

config.vm.provider :virtualbox do |vb|
  vb.cpus = 1
  vb.customize ["modifyvm", :id, "--nictype1", "virtio" ]
  vb.customize ["modifyvm", :id, "--nictype2", "virtio" ]
end

config.vm.provision "shell", inline: <<-SHELL
  #{BOOTSTRAP(name)}
  #{COMPLETE()}
SHELL
