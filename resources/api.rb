# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Resource:: api
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

actions :request, :create, :update, :delete

attribute :path, kind_of: String, name_attribute: true
attribute :data, kind_of: Hash, default: {}
attribute :debug, kind_of: [TrueClass, FalseClass],
                  default: Chef::Config[:log_level] == :debug
attribute :ignore_failure, kind_of: [TrueClass, FalseClass], default: false

def initialize(*args)
  super
  @action = :request
end
