class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
  end

  include RailsSettings::Extend

  def self.roles
    roles = ["administrator", "user", "editor"]
  end

  def self.settings
    settings = {
      locale: {
        accepted_values: (I18n.available_locales - [:"zh-CN"] - [:"zh-TW"]).map(&:to_s),
      },
      nodes_per_page: {
        accepted_values: ["10", "20", "50", "100"],
      },
      export_selected_variant: {
        accepted_values: {
          "id_space_name_newline" => "#{I18n.t('nodes.thead.id_label')} #{I18n.t('nodes.thead.name_label')}<br>...",
          "id_comma" => "#{I18n.t('nodes.thead.id_label')},...",
         },
      },
    }
  end
end
