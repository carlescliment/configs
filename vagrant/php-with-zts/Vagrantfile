Vagrant.configure("2") do |config|
  config.vm.box = "debian-607-x64-vbox4210"
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-607-x64-vbox4210.box"

  config.vm.network "private_network", ip: "192.168.56.101"
  config.vm.network :forwarded_port, guest: 22, host: 7885

  config.vm.usable_port_range = (10200..10500)


  config.vm.provision "shell" do |kg|
    kg.path = "provision/shell/packages.sh"
  end
  config.vm.provision "shell" do |kg|
    kg.path = "provision/shell/php.sh"
  end
end