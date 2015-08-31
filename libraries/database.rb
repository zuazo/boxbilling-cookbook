# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Library:: database
# Author:: Raul Rodriguez (<raul@onddo.com>)
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
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

module BoxBilling
  # Interact with BoxBilling database
  class Database
    ADMIN_SQL_WHERE = {
      role: 'admin',
      status: 'active'
    } unless defined?(::BoxBilling::Database::ADMIN_SQL_WHERE)

    def initialize(options = {})
      @conn_string = options
      @conn_string[:adapter] = 'mysql'
      @conn_string[:logger] = Chef::Log
    end

    def connect(&block)
      Sequel.connect(@conn_string, &block)
    end

    def generate_admin_api_token
      # TODO: UPDATE updated_at field ?
      generatepassword(32).tap do |api_token|
        connect do |db|
          db[:admin]
            .where(ADMIN_SQL_WHERE).limit(1).update(api_token: api_token)
        end
      end
    end

    def admin_api_token
      connect do |db|
        begin
          result = db[:admin].select(:api_token).where(ADMIN_SQL_WHERE).first
          return nil if result.nil?
          result[:api_token]
        rescue Sequel::DatabaseError
          nil
        end
      end
    end

    def database_empty?
      connect { |db| db.tables.empty? }
    end

    protected

    def generatepassword(len = 8)
      # Based on secure_password method from openssl cookbook
      pw = ''
      while pw.length < len
        pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
      end
      pw[0, len]
    end
  end
end
