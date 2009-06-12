require 'spec_helper'
require 'contacts/google_oauth'
require 'uri'

describe Contacts::GoogleOAuth do

  before(:each) do
    @path = Dir.getwd + '/spec/feeds/'
    
    FakeWeb::register_uri(:post,
                          "https://www.google.com:443/accounts/OAuthGetRequestToken",
                          :string => "oauth_token=4%2FyS76XqaZIII50nWATUf1HCnTumtM&oauth_token_secret=h76KHDvZj1UeclHIkO47j6K4&oauth_callback_confirmed=true")
    
    @google = Contacts::GoogleOAuth.new(@path + 'contacts.yml')
  end
 
  after :each do
    FakeWeb.clean_registry
  end
  
  it 'has a default user' do
    @google.user.should == 'default'
  end

  it 'generates an URI for the 2 legs auth' do
    uri = URI.parse @google.authentication_url()
    uri.to_s.should == "https://www.google.com/accounts/OAuthAuthorizeToken?oauth_callback=http%3A%2F%2Fyoan.dosimple.ch%2F&oauth_token=4%2FyS76XqaZIII50nWATUf1HCnTumtM"
  end

  it 'can be serialized' do
    dump = Marshal.dump(@google)

    google = Marshal.load(dump)

    google.request_token.token.should == @google.request_token.token
    google.user.should == @google.user
    google.consumer.secret.should == @google.consumer.secret
  end
  
end
