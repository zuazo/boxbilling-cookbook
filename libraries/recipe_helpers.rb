
module BoxBilling
  module RecipeHelpers

    def self.setup(host, params)
      uri = URI.parse('http://localhost/install/index.php?a=install')
      http = Net::HTTP.new(uri.host)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Host'] = host
      request['User-Agent'] = Chef::REST::RESTRequest.user_agent
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
