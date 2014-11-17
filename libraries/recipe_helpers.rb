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
