# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Recipe:: _apache
# Author:: Raul Rodriguez (<raul@onddo.com>)
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014-2015 Onddo Labs, SL.
# License:: Apache License, Version 2.0
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

Chef::Recipe.send(:include, ::BoxBilling::RecipeHelpers)

include_recipe 'apache2::default' # required before php for Fedora support.
include_recipe 'php'

#==============================================================================
# Install IonCube loader
#==============================================================================

if boxbilling_lt4?
  ioncube_file = ::File.join(Chef::Config[:file_cache_path],
                             'ioncube_loaders.tar.gz')

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
      tar xfz '#{ioncube_file}' --strip-components=1 --no-same-owner \
        --wildcards --no-anchored '*.so' &&
      echo "zend_extension = $(pwd)/ioncube_loader_lin_$(php -v | \
        grep -o '[0-9][.][0-9][0-9]*' | head -1).so" > \
        '#{node['php']['ext_conf_dir']}/20ioncube.ini'
      EOF
    creates ::File.join(node['php']['ext_conf_dir'], '20ioncube.ini')
  end
end

#==============================================================================
# Install Apache
#==============================================================================

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
    ssl true
    ssl_key cert.key_path
    ssl_cert cert.cert_path
    ssl_chain cert.chain_path
    ssl_ca cert.ca_cert_path
    allow_override 'All'
    enable true
  end
end
