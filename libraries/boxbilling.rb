require 'uri'
require 'net/http'

module BoxBilling
  @@version = {}

  def self.get_version_from_url(url)
      @@version[url] ||= begin
        version_regex = /\b\d+\.\d+\.\d+\b/
        version = nil
        if m = version_regex.match(url)
          version = m[0]
        else
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host)
          http.request_get(uri.request_uri) do |response|
            version = response['location'][version_regex] if response['location']
          end
        end
        Chef::Application.fatal!('Cannot get BoxBilling version from download URL') if not version
        version
      end
    end
end
