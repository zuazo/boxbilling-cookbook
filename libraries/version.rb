# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Library:: version
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
  # Get BoxBilling version number from URL
  module Version
    unless defined?(::BoxBilling::Version::VERSION_REGEX)
      VERSION_REGEX = /\b\d+\.\d+\.\d+\b/
    end

    def self.from_url_headers(url)
      version = nil
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host)
      http.request_get(uri.request_uri) do |response|
        version = response['location'][VERSION_REGEX] if response['location']
      end
      version
    end

    def self.from_url(url)
      version =
        if VERSION_REGEX.match(url).nil?
          from_url_headers(url)
        else
          Regexp.last_match[0]
        end
      fail 'Cannot get BoxBilling version from download URL' if version.nil?
      version
    end
  end
end
