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
      ::BoxBilling.get_version_from_url(node['boxbilling']['download_url'])
    end

    def boxbilling3?
      boxbilling_version.split('.')[0] == '3'
    end

    def boxbilling4?
      boxbilling_version.split('.')[0] == '4'
    end

    def database_empty?
      db_password = encrypted_attribute_read(['boxbilling', 'config', 'db_password'])
      BoxBilling::Database.new({
        :host => node['boxbilling']['config']['db_host'],
        :database => node['boxbilling']['config']['db_name'],
        :user     => node['boxbilling']['config']['db_user'],
        :password => db_password,
      }).database_empty?
    end

  end
end
