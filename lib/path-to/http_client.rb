require "httparty"
require "uri"

module PathTo
  #
  # path-to's default HTTPClient.  Any Object (ours just happens to be a Class that includes HTTParty) that provides get, put, post and
  # delete for a String path and optional additional parameters will do.
  #
  # If you only need one such object, simply pass it in as a parameter when constructing your Application object.  Override
  # Path#http_client if you need more control than that.
  #
  class HTTPClient
    include HTTParty
    
    Request::SupportedHTTPMethods.push(Net::HTTP::Head)
    

    #
    # HEAD request, returns some sort of NET::HTTPResponse
    #
    # A bit ugly and out of place this, but HTTParty doesn's support HEAD yet.
    # (@jnunemaker@asplake there is a patch for head requests I need to pull in)
    #
    def self.head(uri_string, headers={})
      uri = URI.parse(uri_string)
      raise URI::InvalidURIError.new("#{uri_string.inspect} is not a valid http URI") unless uri.kind_of?(URI::HTTP) && uri.host

      Net::HTTP.new(uri.host, uri.port).start do |http|
        return http.request(Net::HTTP::Head.new(uri.request_uri, headers))
      end
    end
  end
end
