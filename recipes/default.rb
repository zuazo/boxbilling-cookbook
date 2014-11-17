#
# Cookbook Name:: boxbilling
# Recipe:: default
#
# Copyright 2013, Onddo Labs, Sl.
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

Chef::Recipe.send(:include, Chef::EncryptedAttributesHelpers)
Chef::Recipe.send(:include, ::BoxBilling::RecipeHelpers)
recipe = self

#==============================================================================
# Install packages needed by the recipe
#==============================================================================

node['boxbilling']['required_packages'].each do |pkg|
  package pkg
end

#==============================================================================
# Initialize autogenerated passwords
#==============================================================================

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

self.encrypted_attributes_enabled = node['boxbilling']['encrypt_attributes']

db_password = encrypted_attribute_write(%w(boxbilling config db_password)) do
  secure_password
end
admin_pass = encrypted_attribute_write(%w(boxbilling admin pass)) do
  secure_password
end
salt = encrypted_attribute_write(%w(boxbilling config salt)) do
  secure_password
end

#==============================================================================
# Install PHP
#==============================================================================

include_recipe 'php'

if %w{ redhat centos scientific fedora suse amazon oracle }.include?(node['platform'])
  include_recipe 'yum-epel' # required by php-mcrypt
end
node['boxbilling']['php_packages'].each do |pkg|
  package pkg
end

#==============================================================================
# Install IonCube loader
#==============================================================================

if boxbilling_lt4?
  ioncube_file = ::File.join(Chef::Config[:file_cache_path], 'ioncube_loaders.tar.gz')

  remote_file 'download ioncube' do
    if node['kernel']['machine'] =~ /x86_64/
      source 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz'
    else
      source 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz'
    end
    path ioncube_file
    action :create_if_missing
  end

  execute 'install ioncube' do
    command <<-EOF
      cd "$(php -i | awk '$1 == "extension_dir" {print $NF}')" &&
      tar xfz '#{ioncube_file}' --strip-components=1 --no-same-owner --wildcards --no-anchored '*.so' &&
      echo "zend_extension = $(pwd)/ioncube_loader_lin_$(php -v | grep -o '[0-9][.][0-9][0-9]*' | head -1).so" > '#{node['php']['ext_conf_dir']}/20ioncube.ini'
      EOF
    creates ::File.join(node['php']['ext_conf_dir'], '20ioncube.ini')
  end
end

#==============================================================================
# Install MySQL
#==============================================================================

if %w{ localhost 127.0.0.1 }.include?(node['boxbilling']['config']['db_host'])
  include_recipe 'boxbilling::mysql'
  include_recipe 'database::mysql'

  mysql_connection_info = {
    :host => 'localhost',
    :username => 'root',
    :password => encrypted_attribute_read(['boxbilling', 'mysql', 'server_root_password']),
  }

  mysql_database node['boxbilling']['config']['db_name'] do
    connection mysql_connection_info
    action :create
  end

  mysql_database_user node['boxbilling']['config']['db_user'] do
    connection mysql_connection_info
    database_name node['boxbilling']['config']['db_name']
    host 'localhost'
    password db_password
    privileges [:all]
    action :grant
  end
end

#==============================================================================
# Download and extract BoxBilling
#==============================================================================

directory node['boxbilling']['dir'] do
  recursive true
end

basename = "BoxBilling-#{boxbilling_version}.zip"
local_file = ::File.join(Chef::Config[:file_cache_path], basename)

remote_file 'download boxbilling' do
  source node['boxbilling']['download_url']
  path local_file
  action :create_if_missing
end

execute 'extract boxbilling' do
  command "unzip -q -u -o '#{local_file}' -d '#{node['boxbilling']['dir']}'"
  creates ::File.join(node['boxbilling']['dir'], 'index.php')
end



#==============================================================================
# Install Apache
#==============================================================================

include_recipe 'apache2::default'
include_recipe 'apache2::mod_php5'
include_recipe 'apache2::mod_rewrite'
include_recipe 'apache2::mod_headers'

# Disable default site
apache_site 'default' do
  enable false
end

# Create virtualhost for BoxBilling
web_app 'boxbilling' do
  template 'apache_vhost.erb'
  docroot node['boxbilling']['dir']
  server_name node['boxbilling']['server_name']
  server_aliases node['boxbilling']['server_aliases']
  headers node['boxbilling']['headers']
  port '80'
  allow_override 'All'
  enable true
end

# Enable ssl
if node['boxbilling']['ssl']
  cert = ssl_certificate 'boxbilling' do
    namespace node['boxbilling']
    notifies :restart, 'service[apache2]'
  end

  include_recipe 'apache2::mod_ssl'

  # Create SSL virtualhost
  web_app 'boxbilling-ssl' do
    template 'apache_vhost.erb'
    docroot node['boxbilling']['dir']
    server_name node['boxbilling']['server_name']
    server_aliases node['boxbilling']['server_aliases']
    headers node['boxbilling']['headers']
    port '443'
    ssl_key cert.key_path
    ssl_cert cert.cert_path
    allow_override 'All'
    enable true
  end
end

#==============================================================================
# Initialize configuration file
#==============================================================================

# set writable directories
%w{ cache log uploads }.map do |data_dir|
  ::File.join('bb-data', data_dir)
end.concat([
  ::File.join('bb-themes', 'boxbilling', 'assets'),
]).each do |dir|
  directory ::File.join(node['boxbilling']['dir'], dir) do
    owner node['apache']['user']
    group node['apache']['group']
    mode 00750
    action :create
  end
end

# set writable files
[
  ::File.join('bb-themes', 'boxbilling', 'config', 'settings.html'),
  ::File.join('bb-themes', 'boxbilling', 'config', 'settings_data.json'),
].each do |dir|
  file ::File.join(node['boxbilling']['dir'], dir) do
    owner node['apache']['user']
    group node['apache']['group']
    mode 00640
    action :touch
  end
end

# create configuration file
template 'bb-config.php' do
  path ::File.join(node['boxbilling']['dir'], 'bb-config.php')
  if recipe.boxbilling_lt4?
    source 'bb3/bb-config.php.erb'
  else
    source 'bb4/bb-config.php.erb'
  end
  owner node['apache']['user']
  group node['apache']['group']
  mode 00640
  variables(
    :timezone => node['boxbilling']['config']['timezone'],
    :db_host => node['boxbilling']['config']['db_host'],
    :db_name => node['boxbilling']['config']['db_name'],
    :db_user => node['boxbilling']['config']['db_user'],
    :db_password => db_password,
    :url => node['boxbilling']['config']['url'],
    :license => node['boxbilling']['config']['license'],
    :locale => node['boxbilling']['config']['locale'],
    :sef_urls => node['boxbilling']['config']['sef_urls'],
    :debug => node['boxbilling']['config']['debug'],
    :salt => salt,
    :api => node['boxbilling']['api_config'] || {}
  )
end

# create api configuration file
template 'api-config.php' do
  path ::File.join(node['boxbilling']['dir'], 'bb-modules', 'mod_api', 'api-config.php')
  source 'api-config.php.erb'
  owner node['apache']['user']
  group node['apache']['group']
  mode 00640
  variables(
    config: node['boxbilling']['api_config']
  )
  only_if { recipe.boxbilling_lt4? }
end

# create htaccess file
template 'boxbilling .htaccess' do
  path ::File.join(node['boxbilling']['dir'], '.htaccess')
  source 'htaccess.erb'
  owner node['apache']['user']
  group node['apache']['group']
  mode 00640
  variables(
    :domain => node['boxbilling']['server_name'].gsub(/^www\./, ''),
    :sef_urls => node['boxbilling']['config']['sef_urls'],
    :boxbilling_lt4 => recipe.boxbilling_lt4?
  )
end

# create database content
mysql_database 'create database content' do
  database_name node['boxbilling']['config']['db_name']
  connection(
    :host => node['boxbilling']['config']['db_host'],
    :username => node['boxbilling']['config']['db_user'],
    :password => db_password
  )
  sql do
    structure_sql =
        ::File.join(node['boxbilling']['dir'], 'install', 'structure.sql')
    content_sql =
        ::File.join(node['boxbilling']['dir'], 'install', 'content.sql')
    sql = ::File.open(structure_sql).read
    ::File.exists?(content_sql) ? sql + ::File.open(content_sql).read : sql
  end
  action :query
  only_if { recipe.database_empty? }
  notifies :restart, 'service[apache2]', :immediately
  notifies :create, 'boxbilling_api[create admin user]', :immediately
end

# create admin user
boxbilling_api 'create admin user' do
  path 'guest/staff'
  data(
    :email => node['boxbilling']['admin']['email'],
    :password => admin_pass,
  )
  ignore_failure true
  action :nothing
end

# remove installation dir
directory 'install dir' do
  path ::File.join(node['boxbilling']['dir'], 'install')
  recursive true
  action :delete
end

#==============================================================================
# Enable cron for background jobs
#==============================================================================

if node['boxbilling']['cron_enabled']
  cron 'boxbilling cron' do
    user node['apache']['user']
    minute '*/5'
    command "php -f '#{node['boxbilling']['dir']}/bb-cron.php'"
  end
else
  cron 'boxbilling cron' do
    user node['apache']['user']
    command "php -f '#{node['boxbilling']['dir']}/bb-cron.php'"
    action :delete
  end
end

#==============================================================================
# Install API requirements
#==============================================================================

include_recipe 'boxbilling::api'
