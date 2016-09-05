class NccNode < AbstractModel
  belongs_to :network
  validates :network, presence: true
  has_many :hw_nodes, dependent: :destroy
  has_many :tickets, dependent: :nullify

  def self.vid_regexp
    /\A0x[0-9a-f]{8}\z/
  end

  validates :vid,
            presence: true,
            format: { with: NccNode.vid_regexp, message: "vid should be like \"#{NccNode.vid_regexp}\"" }

  def availability
    availability = false
    response = {}
    accessips = self.accessips
    if accessips.empty?
      response[:errors] = [{
        title: "internal",
        detail: "no-accessips",
      }]
      return response
    else
      if Rails.env.test?
        availability = true
      else
        accessips.each do |accessip|
          http_request = Settings.checker.gsub("{ip}", accessip).gsub("{token}", ENV["CHECKER_TOKEN"])
          http_response = HTTParty.get(http_request)
          availability ||= http_response.parsed_response["data"]["availability"] if http_response.code == :ok
          break if availability
        end
      end
    end
    response[:data] = { "availability" => availability }
    response
  end

  def accessips
    accessips = []
    HwNode.where(ncc_node: self).each do |hw_node|
      accessip = hw_node.accessip
      accessips.push accessip if accessip
    end
    accessips
  end
end
