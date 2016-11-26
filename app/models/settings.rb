# RailsSettings Model
class Settings < RailsSettings::CachedSettings
  def self.set_defaults
    Settings.unscoped.where("thing_id is null").destroy_all
    Settings.values.each do |name, props|
      if props[:default_value]
        value = props[:default_value]
      else
        value = ""
      end
      Settings.create!(var: name, value: value)
    end
  end

  def self.values
    boolean_values = {
      # db_value => translation
      "true" => "boolean.true",
      "false" => "boolean.false",
    }

    values = {
      "locale" => {
        type: :radio,
        accepted_values: Hash[available_locales.each_slice(1).to_a],
        default_value: Rails.configuration.i18n.default_locale.to_s,
      },

      "support_email" => {
        type: :text,
      },

      "checker_api" => {
        type: :text,
        default_value: "http://localhost:8080/?ip=\{ip}&token=\{token}",
      },

      "networks_to_ignore" => {
        type: :text,
        default_value: "6670,6671",
      },

      "nodes_per_page" => {
        type: :radio,
        default_value: "20",
        accepted_values: {
          # using db_value in view
          "10" => nil,
          "20" => nil,
          "50" => nil,
          "100" => nil,
        },
      },

      "export_selected_variant" => {
        type: :radio,
        default_value: "id_space_name_newline",
        accepted_values: {
          "id_space_name_newline" => "shared.id_space_name_newline",
          "id_comma" => "shared.id_comma",
          "csv" => "shared.csv",
        },
      },

      "disable_api" => {
        type: :radio,
        default_value: "false",
        accepted_values: boolean_values,
      },

      "nodename_api_enabled" => {
        type: :radio,
        default_value: "false",
        accepted_values: boolean_values,
      },

      "iplirconf_api_enabled" => {
        type: :radio,
        default_value: "false",
        accepted_values: boolean_values,
      },

      "ticket_api_enabled" => {
        type: :radio,
        default_value: "false",
        accepted_values: boolean_values,
      },

      "mailer_default_from" => {
        type: :text,
        default_value: "vi@example.com",
      },

      "host" => {
        type: :text,
        default_value: "https://vi.example.com",
      },
    }
  end


  def self.available_locales
    # ["ru", "en", ...]
    yml_files = Dir.entries("config/locales").reject { |file| file !~ /.*yml/ }
    yml_files.map { |file| file.gsub(".yml", "") }
  end
end
