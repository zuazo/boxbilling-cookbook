#
# Cookbook Name:: boxbilling
# Recipe:: mysql
#
# Copyright 2014, Onddo Labs, Sl.
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

include_recipe 'mysql::server'

Chef::Recipe.send(:include, Opscode::OpenSSL::Password) # include the #secure_password method

def mysql_password(user)
  key = "server_#{user}_password"
  if Chef::Config['solo']
    if node['boxbilling']['mysql'][key].nil?
      password = secure_password
      node.set['boxbilling']['mysql'][key] = secure_password
    end
    node['boxbilling']['mysql'][key]
  else # chef_client
    include_recipe 'encrypted_attributes'

    if Chef::EncryptedAttribute.exists?(node['boxbilling']['mysql'][key])
      Chef::EncryptedAttribute.update(node.set['boxbilling']['mysql'][key])
      Chef::EncryptedAttribute.load(node['boxbilling']['mysql'][key])
    else
      password = secure_password
      node.set['boxbilling']['mysql'][key] = Chef::EncryptedAttribute.create(password)
      password
    end

  end
end

recipe = self
mysql_service node['mysql']['service_name'] do
  version node['mysql']['version']
  port node['mysql']['port']
  data_dir node['mysql']['data_dir']
  server_root_password recipe.mysql_password('root')
  server_debian_password recipe.mysql_password('debian')
  server_repl_password recipe.mysql_password('repl')
  allow_remote_root node['mysql']['allow_remote_root']
  remove_anonymous_users node['mysql']['remove_anonymous_users']
  remove_test_database node['mysql']['remove_test_database']
  root_network_acl node['mysql']['root_network_acl']
  action :create
end
