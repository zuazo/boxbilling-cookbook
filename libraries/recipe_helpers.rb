
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

    def boxbilling_setup(host, params)
      uri = URI.parse('http://localhost/install/index.php?a=install')
      http = Net::HTTP.new(uri.host)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Host'] = host
      request['User-Agent'] = if defined?(Chef::HTTP::HTTPRequest)
        Chef::HTTP::HTTPRequest.user_agent
      else
        Chef::REST::RESTRequest.user_agent
      end
      request.set_form_data(params)
      response = http.request(request)
      if (response.code.to_i >= 400)
        error_msg = "#{self.name}##{__method__.to_s}: #{response.code} #{response.message}"
        Chef::Application.fatal!(error_msg)
      elsif response.body != 'ok'
        error_msg = "#{self.name}##{__method__.to_s}: #{response.body}"
        Chef::Application.fatal!(error_msg)
      end
    end

  end
end
