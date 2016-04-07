class Node < ActiveRecord::Base
  belongs_to :network
  validates :vipnet_id, presence: true
  validates :network_id, presence: true
  validates :name, presence: true
  default_scope { order(created_at: :desc) }

  def self.searchable
    searchable = {
      "vipnet_id" => "vipnet_id",
      "name" => "name",
      "ips" => { "ips" => "summary" },
      "vipnet_version" => { "vipnet_version" => "summary" },
      "deleted_at" => "deleted_at::text",
      "created_first_at" => "created_first_at::text"
    }
  end

  def self.categories
    categories = { "A" => "client", "S" => "server", "G" => "group" }
  end

  def self.normalize_vipnet_id(vipnet_id)
    # 0123ABCD
    if vipnet_id =~ /[0-9A-F]{8}/
      return "0x" + vipnet_id.downcase
    end
    "0x0123abcd"
  end

  def self.network(vipnet_id)
    # 0x|0123|abcd
    vipnet_id[2..5].to_i(16).to_s(10)
  end

  def accessips
    accessips = Array.new
    Iplirconf.all.each do |iplirconf|
      iplirconf.sections.each do |_, section|
        accessips.push(eval(section)["accessip"]) if eval(section)["vipnet_id"] == self.vipnet_id
      end
    end
    accessips.reject!{ |a| a.nil? }
    accessips
  end

  def availability
    require "httparty"
    availability = false
    response = Hash.new
    accessips = self.accessips
    if accessips.empty?
      response["status"] = "error"
      response["message"] = "no accessips"
      return response
    else
      accessips.each do |accessip|
        http_request = Settings.checker.gsub("#\{ip}", accessip).gsub("#\{token}", ENV["CHECKER_TOKEN"])
        http_response = HTTParty.get(http_request)
        availability ||= http_response.parsed_response["availability"] if http_response.code == 200
        break if availability
      end
    end
    response["status"] = "success"
    response["availability"] = availability
    response
  end

  def ips_summary
    ips_summary = Array.new
    self.ips.each { |_, ips_array| ips_summary += ips_array }
    ips_summary = ips_summary.uniq.join(", ")
  end

  def vipnet_versions_summary
    vipnet_versions = Array.new
    self.vipnet_version.each { |_, v| vipnet_versions.push(v) unless v.nil? }
    uniq_vipnet_versions = vipnet_versions.uniq
    return "" if uniq_vipnet_versions.size == 0
    return uniq_vipnet_versions[0] if uniq_vipnet_versions.size == 1
    return "?" if uniq_vipnet_versions.size > 1
  end

end
