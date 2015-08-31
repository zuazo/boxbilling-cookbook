# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Library:: api
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

require 'json'

module BoxBilling
  # Send requests to BoxBilling API
  module API
    # rubocop:disable Style/ClassVars
    unless defined?(::BoxBilling::API::DEFAULT_OPTIONS)
      DEFAULT_OPTIONS = {
        path: '/',
        ssl: false,
        data: {},
        host: 'localhost',
        user: 'admin',
        api_token: nil,
        referer: nil,
        debug: false,
        endpoint: '/api%{path}'
      }
    end

    @@cookie = nil

    def self.cookie
      @@cookie
    end

    def self.cookie=(arg)
      @@cookie = arg
    end

    # rubocop:enable Style/ClassVars

    def self.default_proto(opts)
      return opts[:proto] unless opts[:proto].nil?
      opts[:ssl] ? 'https' : 'http'
    end

    def self.default_port(opts)
      return opts[:port] unless opts[:port].nil?
      opts[:ssl] ? 443 : 80
    end

    def self.default_path(opts)
      return opts[:path] if opts[:path][0] == '/'
      "/#{opts[:path]}" unless opts[:path][0] == '/'
    end

    def self.default_full_path(opts)
      opts[:endpoint] % { path: opts[:path] }
    end

    def self.parse_args(args)
      DEFAULT_OPTIONS.merge(args).tap do |opts|
        opts[:port] = default_port(opts)
        opts[:proto] = default_proto(opts)
        opts[:path] = default_path(opts)
        opts[:full_path] = default_full_path(opts)
      end
    end

    def self.create_uri(opts)
      URI.parse(
        "#{opts[:proto]}://#{opts[:host]}:#{opts[:port]}#{opts[:full_path]}"
      )
    end

    def self.create_http(uri, opts)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.set_debug_output Chef::Log if opts[:debug]
        next unless opts[:proto] == 'https'
        require 'net/https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def self.user_agent
      if defined?(Chef::HTTP::HTTPRequest)
        Chef::HTTP::HTTPRequest.user_agent
      else
        Chef::REST::RESTRequest.user_agent
      end
    end

    def self.create_request_headers(request, opts)
      request['Content-Type'] = 'application/json'
      request['Referer'] = opts[:referer] unless opts[:referer].nil?
      request['User-Agent'] = user_agent
      request['Cookie'] = cookie unless cookie.nil?
      request
    end

    def self.create_request(uri, opts)
      Net::HTTP::Post.new(uri.request_uri).tap do |request|
        create_request_headers(request, opts)
        unless opts[:api_token].nil?
          request.basic_auth opts[:user], opts[:api_token]
        end
        request.body = opts[:data].to_json
      end
    end

    def self.parse_cookie(response)
      return unless response['Set-Cookie'].is_a?(String)
      self.cookie = response['set-cookie'].split(';')[0]
      Chef::Log.debug("#{name}##{__method__} cookie: #{cookie}")
    end

    def self.parse_http_response(resp)
      return resp unless resp.code.to_i >= 400
      error_msg = "#{name}##{__method__}: #{resp.code} #{resp.message}"
      fail error_msg
    end

    def self.parse_json_response(response)
      resp_json = JSON.parse(response.body, symbolize_names: true)
      unless resp_json[:error].nil?
        error = resp_json[:error]
        if error.key?(:message)
          error_msg = "#{name}##{__method__}: #{error[:message]}"
        end
        fail error_msg
      end
      resp_json[:result]
    end

    def self.parse_response(response)
      parse_cookie(response)
      parse_http_response(response)
      parse_json_response(response)
    end

    def self.request(args)
      opts = parse_args(args)
      uri = create_uri(opts)
      http = create_http(uri, opts)
      req = create_request(uri, opts)
      resp = http.request(req)
      parse_response(resp).tap do |res|
        if opts[:debug]
          Chef::Log.info("#{name}##{__method__} #{opts[:path]} result: #{res}")
        end
      end
    end
  end
end
