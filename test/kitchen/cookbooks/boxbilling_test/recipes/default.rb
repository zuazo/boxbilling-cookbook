#
# Cookbook Name:: boxbilling_test
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

node.default['mysql']['server_root_password'] = 'vagrant_root'
node.default['mysql']['server_debian_password'] = 'vagrant_debian'
node.default['mysql']['server_repl_password'] = 'vagrant_repl'

node.default['boxbilling']['admin']['pass'] = 'admin_pass'
node.default['boxbilling']['config']['db_password'] = 'database_pass'
node.default['boxbilling']['config']['license'] = 'dummy_license'
node.default['boxbilling']['config']['url'] = 'http://localhost:8080/'
node.default['boxbilling']['config']['sef_urls'] = true

include_recipe 'boxbilling'
