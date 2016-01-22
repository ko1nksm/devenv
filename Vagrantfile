# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'vagrant-dev/vagrant-dev'

STORAGE_DIR = ENV['HOME'] unless defined? STORAGE_DIR

Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"

  config.vm.define 'default', primary: true

  config.vm.provider :virtualbox do |vb|
    vb.cpus = 4
    vb.memory = 2048
    vb.customize ['modifyvm', :id, '--paravirtprovider', 'kvm' ]
    vb.customize ['modifyvm', :id, '--bioslogofadein', 'off']
    vb.customize ['modifyvm', :id, '--bioslogofadeout', 'off']
    vb.customize ['modifyvm', :id, '--bioslogodisplaytime', 0]
    vb.customize ['setextradata', :id, 'VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled', 0]
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile
  SHELL

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

  VagrantDev.install(config) do |dev|
    config.vm.provision "shell", inline: <<-SHELL
      #{BOOTSTRAP()}
      create-partition "/dev/sdb"
      mount-partition "HOME" "/dev/sdb1" "/home"
      create-user "#{USERNAME}" "#{USERNAME}" "#{READ KEY_FILE}"
      create-setup "#{USERNAME}" '#{SETUP}'
      #{COMPLETE}
    SHELL

    dev.enumerate_vms(File.dirname(__FILE__)) do |name, config, include_vm|
      config.vm.hostname = name + '.local'
      config.vm.provider :virtualbox do |vb|
        vb.name = name + '@devenv'
        vb.description <<-HERE.gsub(/^\s+/, '')
          HOST: #{name}.local
        HERE
        vb.attach_storage "#{name}-home.vdi", **{
          storagectl: 'IDE Controller',
          port: 0,
          device: 1,
          type: 'hdd',
          size: 10240,
          basedir: STORAGE_DIR,
        }
      end
      include_vm.call
    end
  end

  config.vm.define 'default', autostart: true
end
