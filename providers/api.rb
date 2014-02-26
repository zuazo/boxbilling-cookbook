
def whyrun_supported?
  true
end

def get_admin_api_token
  db = BoxBilling::Database.new({
    :database => node['boxbilling']['config']['db_name'],
    :user     => node['boxbilling']['config']['db_user'],
    :password => node['boxbilling']['config']['db_password'],
  })
  db.get_admin_api_token || begin
    db.generate_admin_api_token
    db.get_admin_api_token
  end
end

# Remove unnecessary slashes
def filter_path(path)
  path.gsub(/(^\/*|\/*$)/, '').gsub(/\/+/, '/')
end

# Get the final action string name for a path (from symbol)
# Examples:
#   (admin/client,   :create) -> create
#   (admin/currency, :create) -> create
#   (admin/product,  :create) -> prepare
def get_action_for_path(path, action)
  case action
  when :create
    case path
    when 'admin/product', 'admin/invoice'
      :prepare
    else
      action
    end
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
    path_ary[0..-2].concat([ "#{action.to_s}_#{path_ary[-1]}" ]).join('/')
  else
    joiner = path_ary.count < 3 ? '/' : '_'
    path + joiner + get_action_for_path(path, action)
  end
end

# Some data values needs to be normalized to allow their
# comparation to work as expected
def normalize_data_value(v)
  v = v.to_s
  v.gsub(/^([0-9]+)[.]0+$/, '\1') # remove 0 decimals
end

# Get "primary keys" from data Hash
def get_primary_keys_from_data(data)
  data.select do |key, value|
    %w{id code type product_id tld}.include?(key.to_s)
  end
end

def data_changed?(old, new)
  case new.class.to_s
  when 'Hash'
    return true unless old.kind_of?(Hash)
    new.inject(false) do |res, (key, value)|
      res || data_changed?(old[key.to_s], value)
    end
  when 'Array'
    return true unless old.kind_of?(Array)
    new.inject(false) do |res, (value, i)|
      res || data_changed?(old[i], value)
    end
  else
    normalize_data_value(old) != normalize_data_value(new)
  end
end

# Check if the path supports an action
def path_supports?(path, action)
  path = filter_path(path)
  action = action.to_sym

  return false if path == 'admin/invoice/tax' and action == :get
  return false if path == 'admin/invoice/tax' and action == :update
  return true
end

def boxbilling_api_request(action=nil, args={})
  api_token = get_admin_api_token
  opts = {
    :path => path_with_action(new_resource.path, action),
    :data => args[:data] || new_resource.data,
    :api_token => api_token,
    :referer => node['boxbilling']['config']['url'],
    :debug => new_resource.debug,
  }

  if args[:ignore_errors].nil? ? new_resource.ignore_errors : args[:ignore_errors]
    begin
      BoxBilling::API.request(opts)
    rescue Exception => e
      Chef::Log.info("Ignored exception: #{e.to_s}") if opts[:debug]
      nil
    end
  else
    BoxBilling::API.request(opts)
  end
end

def boxbilling_api_request_read(args={})
  path = filter_path(new_resource.path)
  if path_supports?(new_resource.path, :get)
    boxbilling_api_request(:get, args)
  else # some objects do not support :get, we should use :get_list
    data_pkeys = get_primary_keys_from_data(new_resource.data)
    page = 1
    begin
      get_list = boxbilling_api_request(:get_list, {
        :data => {
          :page => page
        }
      })
      get_list['list'].each do |item|
        unless data_changed?(get_primary_keys_from_data(item), data_pkeys)
          return item
        end
      end
      page = page + 1
    end while page <= get_list['pages']
    return nil
  end
end

action :request do
  converge_by("Request #{new_resource}: #{new_resource.data}") do
    boxbilling_api_request
  end
end

action :create do
  read_data = boxbilling_api_request_read({
    :ignore_errors => true,
  })

  if read_data.nil?
    converge_by("Create #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:create)
      # run an update after the :create, required by some paths,
      # some values are ignored/not_saved by the create action
      boxbilling_api_request(:update) if path_supports?(new_resource.path, :update)
    end
  elsif data_changed?(read_data, new_resource.data)
    converge_by("Update #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:update)
    end
  end
end

action :update do
  read_data = boxbilling_api_request_read

  if data_changed?(read_data, new_resource.data)
    converge_by("Update #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:update)
    end
  end
end

action :delete do
  read_data = boxbilling_api_request_read({
    :ignore_errors => true,
  })

  unless read_data.nil?
    converge_by("Delete #{new_resource}: #{new_resource.data}") do
      boxbilling_api_request(:delete)
    end
  end
end
