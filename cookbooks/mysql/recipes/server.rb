#
# Cookbook Name:: mysql
# Recipe:: default
#
# Copyright 2008-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "mysql::client"

# generate all passwords
node.set_unless['mysql']['server_debian_password'] = secure_password
node.set_unless['mysql']['server_root_password']   = secure_password
node.set_unless['mysql']['server_repl_password']   = secure_password

if platform?(%w{debian ubuntu})

  directory "/var/cache/local/preseeding" do
    owner "root"
    group node['mysql']['root_group']
    mode 0755
    recursive true
  end

  execute "preseed mysql-server" do
    command "debconf-set-selections /var/cache/local/preseeding/mysql-server.seed"
    action :nothing
  end

  template "/var/cache/local/preseeding/mysql-server.seed" do
    source "mysql-server.seed.erb"
    owner "root"
    group node['mysql']['root_group']
    mode "0660"
    notifies :run, resources(:execute => "preseed mysql-server"), :immediately
  end

  template "#{node['mysql']['conf_dir']}/debian.cnf" do
    source "debian.cnf.erb"
    owner "root"
    group node['mysql']['root_group']
    mode "0660"
  end

end

if platform? 'windows'
  package_file = node['mysql']['package_file']

  remote_file "#{Chef::Config[:file_cache_path]}/#{package_file}" do
    source node['mysql']['url']
    not_if { File.exists? "#{Chef::Config[:file_cache_path]}/#{package_file}" }
  end

  windows_package node['mysql']['package_name'] do
    source "#{Chef::Config[:file_cache_path]}/#{package_file}"
  end

  def package(*args, &blk)
    windows_package(*args, &blk)
  end
end

package node['mysql']['package_name'] do
  action :install
end

directory node['mysql']['confd_dir'] do
  owner "mysql" unless platform? 'windows'
  group "mysql" unless platform? 'windows'
  action :create
  recursive true
end

if platform? 'windows'
  require 'win32/service'

  windows_path node['mysql']['bin_dir'] do
    action :add
  end

  windows_batch "install mysql service" do
    command "\"#{node['mysql']['bin_dir']}\\mysqld.exe\" --install #{node['mysql']['service_name']}"
    not_if { Win32::Service.exists?(node['mysql']['service_name']) }
  end
end

service "mysql" do
  service_name node['mysql']['service_name']
  if node['mysql']['use_upstart']
    restart_command "restart mysql"
    stop_command "stop mysql"
    start_command "start mysql"
  end
  supports :status => true, :restart => true, :reload => true
  action :nothing
end

skip_federated = case node['platform']
                 when 'fedora', 'ubuntu', 'amazon'
                   true
                 when 'centos', 'redhat', 'scientific'
                   node['platform_version'].to_f < 6.0
                 else
                   false
                 end

template "#{node['mysql']['conf_dir']}/my.cnf" do
  source "my.cnf.erb"
  owner "root" unless platform? 'windows'
  group node['mysql']['root_group'] unless platform? 'windows'
  mode "0644"
  notifies :restart, resources(:service => "mysql"), :immediately
  variables :skip_federated => skip_federated
end

unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end

# set the root password on platforms
# that don't support pre-seeding
unless platform?(%w{debian ubuntu})

  execute "assign-root-password" do
    command "\"#{node['mysql']['mysqladmin_bin']}\" -u root password \"#{node['mysql']['server_root_password']}\""
    action :run
    only_if "\"#{node['mysql']['mysql_bin']}\" -u root -e 'show databases;'"
  end

end

grants_path = node['mysql']['grants_path']

begin
  t = resources("template[#{grants_path}]")
rescue
  Chef::Log.info("Could not find previously defined grants.sql resource")
  t = template grants_path do
    source "grants.sql.erb"
    owner "root" unless platform? 'windows'
    group node['mysql']['root_group'] unless platform? 'windows'
    mode "0770"
    action :create
  end
end

if platform? 'windows'
  windows_batch "mysql-install-privileges" do
    command "\"#{node['mysql']['mysql_bin']}\" -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"#{grants_path}\""
    action :nothing
    subscribes :run, resources("template[#{grants_path}]"), :immediately
  end
else
  execute "mysql-install-privileges" do
    command "\"#{node['mysql']['mysql_bin']}\" -u root #{node['mysql']['server_root_password'].empty? ? '' : '-p' }\"#{node['mysql']['server_root_password']}\" < \"#{grants_path}\""
    action :nothing
    subscribes :run, resources("template[#{grants_path}]"), :immediately
  end
end
