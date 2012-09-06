maintainer       "lamtq."
maintainer_email "thanquoclam@gmail.com"
license          "Apache 2.0"
description      "Chef recipes for netcatcher."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

recipe "NetCatcher", "Installs and configures NetCatcher LAMP stack on a single system"

%w{ php openssl }.each do |cb|
  depends cb
end

depends "apache2", ">= 0.99.4"
depends "mysql", ">= 1.0.5"

%w{ debian ubuntu }.each do |os|
  supports os
end
 
attribute "NetCatcher/dir",
  :display_name => "NetCatcher installation directory",
  :description => "Location to place NetCatcher files.",
  :default => "/vagrant/server"
  
attribute "NetCatcher/db/database",
  :display_name => "NetCatcher MySQL database",
  :description => "NetCatcher will use this MySQL database to store its data.",
  :default => "netcatcher"

attribute "NetCatcher/db/user",
  :display_name => "NetCatcher MySQL user",
  :description => "NetCatcher will connect to MySQL using this user.",
  :default => "netcatcherdb"

attribute "NetCatcher/db/password",
  :display_name => "NetCatcher MySQL password",
  :description => "Password for the NetCatcher MySQL user.",
  :default => "randomly generated"

attribute "NetCatcher/keys/auth",
  :display_name => "NetCatcher auth key",
  :description => "NetCatcher auth key.",
  :default => "randomly generated"

attribute "NetCatcher/keys/secure_auth",
  :display_name => "NetCatcher secure auth key",
  :description => "NetCatcher secure auth key.",
  :default => "randomly generated"

attribute "NetCatcher/keys/logged_in",
  :display_name => "NetCatcher logged-in key",
  :description => "NetCatcher logged-in key.",
  :default => "randomly generated"

attribute "NetCatcher/keys/nonce",
  :display_name => "NetCatcher nonce key",
  :description => "NetCatcher nonce key.",
  :default => "randomly generated"
  
attribute "NetCatcher/server_aliases",
  :display_name => "NetCatcher Server Aliases",
  :description => "NetCatcher Server Aliases",
  :default => "FQDN"
  
attribute "NetCatcher/server_name",
  :display_name => "NetCatcher Server Name",
  :description => "NetCatcher Server Name",
  :default => "netcatcher.in"
