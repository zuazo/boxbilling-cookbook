# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Library:: api
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

require 'json'

module BoxBilling
  # Send requests to BoxBilling API
  module API
    @cookie = nil

    def self.request(args)
      # Read options from args
      opts = {
        path: '/',
        ssl: false,
        data: {},
        host: 'localhost',
        user: 'admin',
        api_token: nil,
        referer: nil,
        debug: false,
        endpoint: '/api%{path}'
      }.merge(args)
      opts[:proto] = opts[:ssl] ? 'https' : 'http' unless opts[:proto]
      opts[:port] = opts[:ssl] ? 443 : 80 unless opts[:port]
      opts[:path] = "/#{opts[:path]}" unless opts[:path][0] == '/'

      # Create HTTP object
      path = opts[:endpoint] % { path: opts[:path] }
      uri = URI.parse("#{opts[:proto]}://#{opts[:host]}:#{opts[:port]}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      if opts[:ssl]
        require 'net/https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.set_debug_output Chef::Log if opts[:debug]

      # Build request
      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type'] = 'application/json'
      req['Referer'] = opts[:referer] unless opts[:referer].nil?
      req['User-Agent'] = if defined?(Chef::HTTP::HTTPRequest)
                            Chef::HTTP::HTTPRequest.user_agent
                          else
                            Chef::REST::RESTRequest.user_agent
                          end
      req['Cookie'] = @cookie unless @cookie.nil?
      req.basic_auth opts[:user], opts[:api_token] unless opts[:api_token].nil?
      req.body = opts[:data].to_json

      # Read response
      resp = http.request(req)
      if resp['Set-Cookie'].is_a?(String)
        @cookie = resp['set-cookie'].split(';')[0]
        Chef::Log.debug("#{name}##{__method__} cookie: #{@cookie}")
      end
      if (resp.code.to_i >= 400)
        error_msg = "#{name}##{__method__}: #{resp.code} #{resp.message}"
        fail error_msg
      else
        resp_json = JSON.parse(resp.body)
        unless resp_json['error'].nil?
          error = resp_json['error']
          if error.key?('message')
            error_msg = "#{name}##{__method__}: #{error['message']}"
            fail error_msg
          else
            fail error_msg
          end
        end
        if opts[:debug]
          Chef::Log.info("#{name}##{__method__} #{opts[:path]} result: "\
            "#{resp_json['result']}")
        end
        return resp_json['result']
      end

      nil
    end
  end
end
