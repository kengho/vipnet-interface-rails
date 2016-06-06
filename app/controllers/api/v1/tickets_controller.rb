class Api::V1::TicketsController < Api::V1::BaseController
  def create
    unless (params[:ticket])
      Rails.logger.error("Incorrect params")
      render plain: "error" and return
    end
    if params[:ticket].class == String
      ticket = eval(params[:ticket])
    elsif params[:ticket].class == ActionController::Parameters
      ticket = params[:ticket]
    end

    nodes = Node.where("vipnet_id = ? AND history = 'false'", ticket[:vipnet_id])
    if nodes.size == 0
      render plain: "ok" and return
    elsif nodes.size == 1
      url_template = ticket[:url_template]
      id = ticket[:id]
      old_node = nodes.first
      new_node = old_node.dup
      new_ids = new_node.tickets[url_template] || "\[\]"
      new_ids = eval(new_ids)
      new_ids.push(id)
      new_ids = new_ids.uniq.sort
      new_node.tickets[url_template] = new_ids
      unless new_node.tickets[url_template] == old_node.tickets[url_template]
        old_node.history = "true"
        old_node.save!
        ids_summary = Array.new
        new_node.tickets.each do |key, ids|
          next if key == "ids_summary"
          ids_summary += ids
        end
        new_node.tickets["ids_summary"] = ids_summary.uniq.sort.join(", ")
        new_node.save!
      end
    elsif nodes.size > 1
      Rails.logger.error("More than one nodename found '#{ticket[:vipnet_id]}'")
      render plain: "error" and return
    end
    render plain: "ok" and return
  end
end
