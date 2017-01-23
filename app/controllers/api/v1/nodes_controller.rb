class Api::V1::NodesController < Api::V1::BaseController
  def index
    @response = {}
    if params[:vid]
      only = params[:only] || ["name"]
      ncc_node = CurrentNccNode.find_by(vid: params[:vid])
    else
      @response[:errors] = [{
        title: "external",
        detail: "Expected vid as param",
        links: {
          related: {
            href: "/api/v1/doc",
          },
        },
      }]

      render json: @response and return
    end

    if only.class != Array
      @response[:errors] = [{
        title: "external",
        detail: "Only should be an array",
        links: {
          related: {
            href: "/api/v1/doc",
          },
        },
      }]

      render json: @response and return
    end

    unless ncc_node
      @response[:errors] = [{ title: "external", detail: "Node not found" }]
      render json: @response and return
    end

    @response[:data] = {}
    avaliable_fileds = %w(
      name ip accessip version version_decoded
      enabled category creation_date creation_date_accuracy
    )
    only_filtered = only & avaliable_fileds
    only_filtered_ncc = only_filtered & NccNode.props_from_nodename.map(&:to_s)
    only_filtered_hw = only_filtered & (
      HwNode.props_from_iplirconf + [:version_decoded]
    ).map(&:to_s)
    if only_filtered_hw.any?
      ncc_node.hw_nodes.each do |hw_node|
        only_filtered_hw.each do |param|
          @response[:data].deep_merge!(
            param => {
              hw_node.coordinator.vid => hw_node[param],
            },
          )
        end

        next unless only_filtered.include?("ip")
        ips = []
        hw_node.node_ips.each { |node_ip| ips.push(IPv4.ip(node_ip.u32)) }

        next unless ips.any?
        @response[:data].deep_merge!(
          "ip" => {
            hw_node.coordinator.vid => ips,
          },
        )
      end
    end
    @response[:data].merge!(ncc_node.attributes.slice(*only_filtered_ncc))

    render json: @response
  end
end
