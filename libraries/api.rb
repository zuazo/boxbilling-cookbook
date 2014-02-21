require 'json'

module BoxBilling
  module API
    @@cookie = nil

    def self.request(args)

      # Read options from args
      opts = {
        :path => '/',
        :ssl => false,
        :data => {},
        :host => 'localhost',
        :user => 'admin',
        :api_token => nil,
        :referer => nil,
        :debug => false,
      }.merge(args)
      opts[:proto] = opts[:ssl] ? 'https' : 'http' unless opts[:proto]
      opts[:port] = opts[:ssl] ? 443 : 80 unless opts[:port]
      opts[:path] = "/#{opts[:path]}" unless opts[:path][0] === '/'

      # Create HTTP object
      uri = URI.parse("#{opts[:proto]}://#{opts[:host]}:#{opts[:port]}/api#{opts[:path]}")
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
      unless @@cookie.nil?
        req['Cookie'] = @@cookie
      end
      req.basic_auth opts[:user], opts[:api_token] unless opts[:api_token].nil?
      req.body = opts[:data].to_json

      # Read response
      resp = http.request(req)
      if resp['Set-Cookie'].kind_of?(String)
        @@cookie = resp['set-cookie'].split(';')[0]
        Chef::Log.debug("#{self.name}##{__method__.to_s} cookie: #{@@cookie}")
      end
      if (resp.code.to_i >= 400)
        error_msg = "#{self.name}##{__method__.to_s}: #{resp.code} #{resp.message}"
        raise error_msg
      else
        resp_json = JSON.parse(resp.body)
        unless resp_json['error'].nil?
          error = resp_json['error']
          if error.has_key?('message')
            error_msg = "#{self.name}##{__method__.to_s}: #{error['message']}"
            raise error_msg
          else
            raise error_msg
          end
        end
        Chef::Log.info("#{self.name}##{__method__.to_s} #{opts[:path]} result: #{resp_json['result'].to_s}") if opts[:debug]
        return resp_json['result']
      end

      return nil
    end

  end
end
