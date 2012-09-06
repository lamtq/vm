include_recipe "apache2"
include_recipe "mysql::server"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "apache2::mod_php5"

gem_package "mysql" do
  action :install
end

execute "mysql-install-nc-privileges" do
  command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" < #{node['mysql']['conf_dir']}/nc-grants.sql"
  action :nothing
end

template "#{node['mysql']['conf_dir']}/nc-grants.sql" do
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :user => node['netcatcher']['db']['user'],
    :password => node['netcatcher']['db']['password'],
    :database => node['netcatcher']['db']['database']
  )
  notifies :run, "execute[mysql-install-nc-privileges]", :immediately
end

execute "create #{node['netcatcher']['db']['database']} database" do
  command "/usr/bin/mysqladmin -u root -p\"#{node['mysql']['server_root_password']}\" create #{node['netcatcher']['db']['database']}"
  not_if do
    # Make sure gem is detected if it was just installed earlier in this recipe
    require 'rubygems'
    Gem.clear_paths
    require 'mysql'
    m = Mysql.new("localhost", "root", node['mysql']['server_root_password'])
    m.list_dbs.include?(node['netcatcher']['db']['database'])
  end
  notifies :create, "ruby_block[save node data]", :immediately unless Chef::Config[:solo]
end

# save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end

apache_site "000-default" do
  enable false
end

web_app "netcatcher" do
  template "netcatcher.conf.erb"
  docroot "#{node['netcatcher']['dir']}"
  server_name node['netcatcher']['server_name']
  server_aliases node['netcatcher']['server_aliases']
end