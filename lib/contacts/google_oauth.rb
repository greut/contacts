require 'yaml'
require 'oauth'
require 'contacts/google'

module Contacts
  class GoogleOAuth < Google
    CONFIG_FILE = File.dirname(__FILE__) + '/../config/contacts.yml'
    SCOPE = "https://www.google.com/m8/feeds/"

    attr_accessor :user, :consumer

    def initialize(config_file=CONFIG_FILE)
      confs = YAML.load_file(config_file)["google_oauth"]
      @oauth_callback = confs["callback"]
      @user = confs["user"] || "default"
      @consumer = OAuth::Consumer.new(confs["consumer_key"],
                                      confs["consumer_secret"],
                                      {:site => "https://www.google.com",
                                       :request_token_path => "/accounts/OAuthGetRequestToken",
                                       :access_token_path => "/accounts/OAuthGetAccessToken",
                                       :authorize_path => "/accounts/OAuthAuthorizeToken"})
            
      @projection = 'thin'
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
      params = {:oauth_callback => @oauth_callback}.update(params)
      request_token.authorize_url params
    end
    
    def request_token
      return @request_token if @request_token
      @request_token = @consumer.get_request_token({:oauth_callback => @oauth_callback},
                                                   :scope => SCOPE)
    end

    def access_token(oauth_verifier = nil)
      return @access_token if @access_token
      @access_token = request_token.get_access_token({:oauth_verifier => oauth_verifier})
    end
    
    def get(params={})
      path = FeedsPath + CGI.escape(@user)
      google_params = translate_parameters(params)
      query = self.class.query_string(google_params)
      access_token.get("#{path}/#{@projection}?#{query}")
    end

  end
end
