class User < ActiveRecord::Base
  validates :role, presence: true,
                   uniqueness: { conditions: -> { where(role: "admin") }}

  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  include RailsSettings::Extend

  def self.roles
    {
      list: %w(admin user editor),
      default: "user",
    }
  end
end
