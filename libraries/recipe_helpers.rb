# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Library:: recipe_helpers
# Author:: Raul Rodriguez (<raul@onddo.com>)
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014-2015 Onddo Labs, SL. (www.onddo.com)
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
  # Helpers for BoxBilling cookbook.
  module RecipeHelpers
    include Chef::EncryptedAttributesHelpers

    def boxbilling_web_server
      node['boxbilling']['web_server']
    end

    def boxbilling_web_service
      boxbilling_web_server == 'apache' ? 'apache2' : boxbilling_web_server
    end

    def boxbilling_web_user
      return nil if boxbilling_web_server.nil?
      node[boxbilling_web_server]['user']
    end

    def boxbilling_web_group
      return nil if boxbilling_web_server.nil?
      node[boxbilling_web_server]['group']
    end

    def boxbilling_upload_cookbook_file_path(file)
      ::File.join(node['boxbilling']['dir'], file)
    end

    def boxbilling_upload_cookbook_file(file)
      # Upload product images
      cookbook_file boxbilling_upload_cookbook_file_path(file) do
        path path
        owner boxbilling_web_user
        group boxbilling_web_group
        mode '00750'
      end

      "#{node['boxbilling']['config']['url']}/#{file}"
    end

    def boxbilling_version
      download_url = node['boxbilling']['download_url']
      # Uses node#run_state as versions cache
      node.run_state["boxbilling_version_cache_#{download_url}"] ||=
        ::BoxBilling::Version.from_url(download_url)
    end

    def boxbilling_installed_version
      node.run_state['boxbilling_installed_version_cache'] ||=
        ::BoxBilling::Version.from_install_dir(node['boxbilling']['dir'])
    end

    def boxbilling_lt4?
      boxbilling_version.to_i < 4
    end

    def boxbilling_database
      BoxBilling::Database.new(
        host: node['boxbilling']['config']['db_host'],
        database: node['boxbilling']['config']['db_name'],
        user: node['boxbilling']['config']['db_user'],
        password: boxbilling_database_password
      )
    end

    def boxbilling_database_password
      encrypted_attribute_read(%w(boxbilling config db_password))
    end

    def boxbilling_database_empty?
      boxbilling_database.database_empty?
    end

    def boxbilling_fresh_install?
      ! ::File.exist?(::File.join(node['boxbilling']['dir'], 'index.php'))
    end

    def boxbilling_update?
      return false unless boxbilling_installed_version
      boxbilling_version != boxbilling_installed_version
    end
  end
end
