# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "lucid32"

  config.vm.forward_port 80, 8686
  config.vm.forward_port 3306, 3386
  config.vm.network :hostonly, "192.168.10.111" 

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "apt"
    chef.add_recipe "apache2"
    chef.add_recipe "apache2::mod_php5"
	chef.add_recipe "mysql"
    chef.add_recipe "mysql::server"
	chef.add_recipe "mysql::client"
	chef.add_recipe "php"
    chef.add_recipe "php::module_mysql"
    chef.add_recipe "nodejs"
    chef.add_recipe "nodejs::npm"
    chef.json = {
      "mysql" => { 
            "server_root_password" => "123", 
            "server_debian_password" => "123"
      }
    }
    chef.add_recipe "netcatcher"
  end
end
