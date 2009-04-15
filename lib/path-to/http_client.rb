require "httparty"

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
  end
end
