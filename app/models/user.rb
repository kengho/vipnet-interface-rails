class User < ActiveRecord::Base
  validates :role, presence: true
  validates :role, uniqueness: {
    conditions: -> { where(role: "administrator") },
  }

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  include RailsSettings::Extend

  def self.roles
    {
      list: %w(administrator user editor),
      default: "user",
    }
  end
end
