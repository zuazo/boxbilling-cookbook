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
