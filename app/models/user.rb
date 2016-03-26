class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  include RailsSettings::Extend

  def self.roles
    roles = [ "administrator", "user", "editor" ]
  end

  def self.settings
    settings = ["locale"]
  end

end
