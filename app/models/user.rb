class User < ActiveRecord::Base
  validates_presence_of :role
  validates_uniqueness_of :role, conditions: -> { where(role: "administrator") }

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  include RailsSettings::Extend

  def self.roles
    {
      list: ["administrator", "user", "editor"],
      default: "user",
    }
  end
end
