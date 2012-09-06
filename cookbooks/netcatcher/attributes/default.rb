#
# Author:: lamtq (thanquoclam@gmail.com)
# Cookbook Name:: netcatcher
# Attributes:: netcatcher
#

# General settings
default['netcatcher']['dir'] = "/vagrant/server"
default['netcatcher']['db']['database'] = "netcatcher"
default['netcatcher']['db']['user'] = "admin"
default['netcatcher']['server_aliases'] = [node['fqdn']]
default['netcatcher']['server_name'] = "netcatcher.in"