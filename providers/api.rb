# encoding: UTF-8
#
# Cookbook Name:: boxbilling
# Provider:: api
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

::Chef::Provider::BoxbillingApi.send(:include, ::BoxBilling::RecipeHelpers)

def whyrun_supported?
  true
end

def admin_api_token
  db = boxbilling_database
  db.admin_api_token || db.generate_admin_api_token
end

# Remove unnecessary slashes
def filter_path(path)
  path.gsub(%r{(^/*|/*$)}, '').gsub(/\/+/, '/')
end

# Get the final action string name for a path (from symbol)
# Examples:
#   (admin/client,   :create) -> create
#   (admin/currency, :create) -> create
#   (admin/product,  :create) -> prepare
def get_action_for_path(path, action)
  case action
  when :create
    %w(admin/product admin/invoice).include?(path) ? :prepare : action
  when :update
    %w(admin/extension/config).include?(path) ? :save : action
  else
    action
  end.to_s
end

# Generate the full URL path, including the action at the end
# Examples:
#   admin/client/create
#   admin/currency/create
#   admin/kb/category_create
#   admin/system/get_params
def path_with_action(path, action)
  path = filter_path(path)
  return path if action.nil?
  path_ary = path.split('/')
  if (path_ary[-1] == 'params')
    path_ary[0..-2].concat(["#{action}_#{path_ary[-1]}"]).join('/')
  else
    joiner = path_ary.count < 3 ? '/' : '_'
    path + joiner + get_action_for_path(path, action)
  end
end

# Some data values needs to be normalized to allow their
# comparison to work as expected
def normalize_data_value(v)
  v = v.to_s
  v.gsub(/^([0-9]+)[.]0+$/, '\1') # remove 0 decimals
end

# Get "primary keys" from data Hash
def get_primary_keys_from_data(data)
  data.select do |key, _value|
    %w(id code type product_id tld action_code).include?(key.to_s)
  end
end

def data_hash_eql?(old, new)
  return false unless old.is_a?(Hash)
  new.inject(true) do |res, (key, value)|
    res && data_eql?(old[key.to_s], value)
  end
end

def data_array_eql?(old, new)
  return false unless old.is_a?(Array)
  new.each.with_index.inject(true) do |res, (value, i)|
    res && data_eql?(old[i], value)
  end
end

# Compares each new value with the old one. Old values that do not
# exists in new are ignored.
def data_eql?(old, new)
  case new.class.to_s
  when 'Hash' then data_hash_eql?(old, new)
  when 'Array' then data_array_eql?(old, new)
  else
    normalize_data_value(old) == normalize_data_value(new)
  end
end

# Compare the primary keys of 2 items.
def same_item?(old, new)
  old_keys = get_primary_keys_from_data(old)
  new_keys = get_primary_keys_from_data(new)
  return false unless new_keys.length
  data_eql?(old_keys, new_keys)
end

PATH_MISSING_ACTIONS = {
  'admin/invoice/tax' => %w(get update),
  'guest/staff' => %w(get get_list update),
  'admin/email/template' => %w(get)
}

# Check if the path supports an action
def path_supports?(path, action)
  path = filter_path(path)
  action = action.to_s

  !PATH_MISSING_ACTIONS.key?(path) ||
    !PATH_MISSING_ACTIONS[path].include?(action)
end

def boxbilling_old_api?
  @old_api ||= boxbilling_lt4?
end

def boxbilling_api_request_default_options(action, args)
  {
    path: path_with_action(new_resource.path, action),
    data: args[:data] || new_resource.data,
    api_token: nil,
    referer: node['boxbilling']['config']['url'],
    ignore_failure: args[:ignore_failure],
    debug: new_resource.debug
  }
end

def boxbilling_api_endpooint
  if node['boxbilling']['config']['sef_urls']
    '/api%{path}'
  elsif boxbilling_old_api?
    '/index.php/api%{path}'
  else
    '/index.php?_url=/api%{path}'
  end
end

def boxbilling_api_request_options(action, args)
  boxbilling_api_request_default_options(action, args).tap do |opts|
    opts[:api_token] = admin_api_token if opts[:path].match(%r{^/?admin/})
    opts[:endpoint] = boxbilling_api_endpooint
  end
end

def ignore_failure?(opts)
  if opts[:ignore_failure].nil?
    new_resource.ignore_failure
  else
    opts[:ignore_failure]
  end
end

def boxbilling_api_request(action = nil, args = {})
  opts = boxbilling_api_request_options(action, args)
  begin
    BoxBilling::API.request(opts)
  rescue StandardError => e
    raise e unless ignore_failure?(opts)
    Chef::Log.warn("Ignored exception: #{e}")
    nil
  end
end

def boxbilling_api_request_read_list(_args)
  page = 1
  loop do
    get_list = boxbilling_api_request(:get_list, data: { page: page })
    get_list['list'].each do |item|
      return item if same_item?(item, new_resource.data)
    end
    page += 1
    break unless page <= get_list['pages']
  end
end

def boxbilling_api_request_read(args = {})
  path = filter_path(new_resource.path)
  if path_supports?(path, :get)
    boxbilling_api_request(:get, args)
  # some objects do not support :get, we should use :get_list
  elsif path_supports?(path, :get_list)
    boxbilling_api_request_read_list(args)
  else
    return nil
  end
end

action :request do
  converge_by("Request #{new_resource}: #{new_resource.data}") do
    boxbilling_api_request
  end
end

action :create do
  read_data = boxbilling_api_request_read(ignore_failure: true)

  if read_data.nil?
    converge_by("Create #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:create)
      # run an update after the :create, required by some paths,
      # some values are ignored/not_saved by the create action
      if path_supports?(new_resource.path, :update)
        boxbilling_api_request(:update)
      end
    end
  # data exists, update
  elsif !data_eql?(read_data, new_resource.data)
    new_data =
      get_primary_keys_from_data(read_data).merge(new_resource.data)
    if path_supports?(new_resource.path, :update)
      converge_by("Update #{new_resource}: #{new_resource.data}") do
        boxbilling_api_request(:update, data: new_data)
      end
    # doesn't support update, use delete and then create
    else
      converge_by("Delete #{new_resource}: #{new_resource.data}") do
        boxbilling_api_request(:delete, data: read_data)
      end
      converge_by("Create #{new_resource}: #{new_resource.data}") do
        boxbilling_api_request(:create)
      end
    end
  end
end

action :update do
  read_data = boxbilling_api_request_read

  unless data_eql?(read_data, new_resource.data)
    converge_by("Update #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:update)
    end
  end
end

action :delete do
  read_data = boxbilling_api_request_read(ignore_failure: true)

  unless read_data.nil?
    converge_by("Delete #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:delete)
    end
  end
end
