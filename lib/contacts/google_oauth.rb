require 'oauth'
require 'contacts/google'

# An extension to the standard OAuth library so we can nicely use Google APIs
module GoogleOAuth
  class RequestToken < OAuth::RequestToken
    def authorize_url(params={})
      params.merge! :oauth_token => token
      params = params.map { |k,v| "%s=%s" % [CGI.escape(k.to_s), CGI.escape(v)] }
      consumer.authorize_url + "?" + params.join("&")
    end
  end
  
  class Consumer < OAuth::Consumer
    def initialize(consumer_key, consumer_secret)
      super(consumer_key,
            consumer_secret,
            {:site => "https://www.google.com",
             :request_token_path => "/accounts/OAuthGetRequestToken",
             :access_token_path => "/accounts/OAuthGetAccessToken",
             :authorize_path => "/accounts/OAuthAuthorizeToken"})
    end
    
    def marshal_load(data)
      initialize(data[:key], data[:secret])
    end
    
    def marshal_dump
      {:key => self.key, :secret => self.secret}
    end
    
    def get_request_token(params={})
      params_str = params.map { |k,v| "%s=%s" % [CGI.escape(k.to_s), CGI.escape(v)] }.join("&")
      uri = URI.parse(request_token_url? ? request_token_url : request_token_path)
      if !uri.query || uri.query == ''
        uri.query = params_str
      else
        uri.query = uri.query + "&" + params_str
      end
      
      response=token_request(http_method, uri.to_s, nil, {})
      GoogleOAuth::RequestToken.new(self, response[:oauth_token], response[:oauth_token_secret])
    end
  end
end

module Contacts
  class GoogleOAuth < Google
    def initialize(consumer_key, consumer_secret, user_id = 'default')
      @consumer = ::GoogleOAuth::Consumer.new(consumer_key, consumer_secret)
      @request_token = @consumer.get_request_token :scope => "https://www.google.com/m8/feeds/"
      @projection = 'thin'
      @user = user_id.to_s
    end
    
    def marshal_load(data)
      @consumer = data[:consumer]
      @request_token = data[:request_token]
      @projection = 'thin'
      @user = data[:user]
    end
    
    def marshal_dump
      {:consumer => @consumer,
       :request_token => @request_token,
       :user => @user}
    end
    
    # Available parameters:
    # - hd: Google Apps domain that should be requested (default nil)
    # - oauth_callback: The URL that the user should be redirected to when he successfully authorized us.
    def authentication_url(params={})
      @request_token.authorize_url params
    end
    
    def access_token
      return @access_token if @access_token
      begin
        @access_token = @request_token.get_access_token
      rescue Net::HTTPServerException
      end
    end
    
    def get(params={})
      path = FeedsPath + CGI.escape(@user)
      google_params = translate_parameters(params)
      query = self.class.query_string(google_params)
      access_token.get("#{path}/#{@projection}?#{query}")
    end
  end
end