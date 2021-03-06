# -*- mode: ruby -*-
# vi: set ft=ruby :
require_relative 'vagrant-dev/vagrant-dev'

$STORAGE_DIR = ENV['HOME']
$NETWORK = '192.168.33.'
$IPADDR_LIST = {
  'test'    => '192.168.33.9',
  'default' => '192.168.33.10',
  'docker'  => '192.168.33.11',
  'dns'     => '192.168.33.12',
  'centos'   => '192.168.33.127',
  'proxy'   => '192.168.33.254',
}
$DOMAIN = "local.int"

Vagrant.configure(2) do |config|
  config.vm.box = "debian8"
  config.vm.box_check_update = false

  config.vm.define 'default', primary: true

  config.vm.provider :virtualbox do |vb|
    vb.cpus = 4
    vb.memory = 2048
    vb.customize ['modifyvm', :id, '--groups', '/devenv']
    vb.customize ['modifyvm', :id, '--bioslogofadein', 'off']
    vb.customize ['modifyvm', :id, '--bioslogofadeout', 'off']
    vb.customize ['modifyvm', :id, '--bioslogodisplaytime', 1]
    vb.customize ['modifyvm', :id, '--biosbootmenu', 'disabled']
    vb.customize ['setextradata', :id, 'VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled', 0]
    vb.customize ["modifyvm", :id, "--nictype1", "Am79C973" ]
    vb.customize ["modifyvm", :id, "--nictype2", "Am79C973" ]
    vb.linked_clone = true
  end

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  VagrantDev.configure(config) do |dev|
    config.vm.provision "shell", inline: <<-SHELL
      #{BOOTSTRAP()}
      include config
      create-partition /dev/sdb
      create-user #{USERNAME} #{USERNAME} adm,staff,docker,systemd-journal /bin/zsh
      mount-partition HOME /dev/sdb1 ~#{USERNAME} #{USERNAME}
      insert-authorized-keys #{USERNAME} #{READ KEY_FILE}
      create-file ~#{USERNAME}/setup.sh #{USERNAME}:#{USERNAME} 755 #{DATA $SETUP}
      #{COMPLETE()}
    SHELL

    dev.vms(File.dirname(__FILE__)) do |vm, config|
      config.vm.network "private_network", ip: $IPADDR_LIST[vm.name]
      config.vm.hostname = "#{vm.name}.#{$DOMAIN}"
      config.vm.provider :virtualbox do |vb|
        vb.name = "#{vm.name}.#{$DOMAIN}"

        is_sata = config.vm.box != "centos7"
        pos = is_sata ? "SATA Controller-1-0" : "IDE Controller-0-1"
        vb.attach_storage "#{vm.name}-home.vdi", pos, 10240, **{
          basedir: $STORAGE_DIR,
        }
      end
      vm.load
    end
  end

  config.vm.define 'default', autostart: true
end
