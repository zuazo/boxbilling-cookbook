# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Recipe:: _nginx
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Onddo Labs, SL.
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

include_recipe 'nginx'
include_recipe 'boxbilling::_php_fpm'

# Disable apache2, required for Debian 6
service 'apache2' do
  action [:stop, :disable]
  only_if { ::File.exist?('/etc/init.d/apache2') }
end

fastcgi_pass =
  "unix:/var/run/php-fpm-#{node['boxbilling']['php-fpm']['pool']}.sock"

template_variables = {
  name: 'boxbilling',
  server_name: node['boxbilling']['server_name'],
  server_aliases: node['boxbilling']['server_aliases'],
  docroot: node['boxbilling']['dir'],
  port: '80',
  fastcgi_pass: fastcgi_pass,
  headers: node['boxbilling']['headers']
}

# Create virtualhost
vhost_file = File.join(node['nginx']['dir'], 'sites-available', 'boxbilling')
template vhost_file do
  source 'nginx_vhost.erb'
  mode 00644
  owner 'root'
  group 'root'
  variables(template_variables)
  notifies :reload, 'service[nginx]'
end

nginx_site 'boxbilling' do
  enable true
end

if node['boxbilling']['ssl']
  cert = ssl_certificate 'boxbilling' do
    namespace node['boxbilling']
    notifies :restart, 'service[nginx]' # TODO: reload?
  end

  ssl_template_variables = template_variables.merge(
    port: '443',
    ssl: true,
    ssl_key: cert.key_path,
    ssl_cert: cert.chain_combined_path
  )

  # Create virtualhost
  ssl_vhost_file =
    File.join(node['nginx']['dir'], 'sites-available', 'boxbilling-ssl')
  template ssl_vhost_file do
    source 'nginx_vhost.erb'
    mode 00644
    owner 'root'
    group 'root'
    variables(ssl_template_variables)
    notifies :reload, 'service[nginx]'
  end

  nginx_site 'boxbilling-ssl' do
    enable true
  end
end
