# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Library:: recipe_helpers
# Author:: Raul Rodriguez (<raul@onddo.com>)
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
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

require 'uri'
require 'net/http'

module BoxBilling
  module RecipeHelpers
    def boxbilling_upload_cookbook_file(file)
      path = ::File.join(node['boxbilling']['dir'], 'bb-uploads', file)

      # Upload product images
      cookbook_file path do
        path path
        owner node['apache']['user']
        group node['apache']['group']
        mode '00750'
      end

      "#{node['boxbilling']['config']['url']}/bb-uploads/#{file}"
    end

    def boxbilling_version
      download_url = node['boxbilling']['download_url']
      # Uses node#run_state as versions cache
      node.run_state["boxbilling_version_cache_#{download_url}"] ||=
        ::BoxBilling::Version.from_url(download_url)
    end

    def boxbilling_lt4?
      boxbilling_version.to_i < 4
    end

    def database_empty?
      db_password = encrypted_attribute_read(%w(boxbilling config db_password))
      BoxBilling::Database.new({
        :host     => node['boxbilling']['config']['db_host'],
        :database => node['boxbilling']['config']['db_name'],
        :user     => node['boxbilling']['config']['db_user'],
        :password => db_password,
      }).database_empty?
    end

  end
end
