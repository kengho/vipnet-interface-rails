class Api::V1::TicketsController < Api::V1::BaseController
  def create
    unless (params[:ticket])
      Rails.logger.error("Incorrect params #{params}")
      render plain: ERROR_RESPONSE and return
    end
    if params[:ticket].class == String
      ticket = eval(params[:ticket])
    elsif params[:ticket].class == ActionController::Parameters
      ticket = params[:ticket]
    end

    old_node = Node.find_by(vipnet_id: ticket[:vipnet_id], history: false)
    if old_node
      url_template = ticket[:url_template]
      id = ticket[:id]
      new_node = old_node.dup
      new_ids = new_node.tickets[url_template] || "\[\]"
      new_ids = eval(new_ids)
      new_ids.push(id)
      new_ids = new_ids.uniq.sort
      new_node.tickets[url_template] = new_ids
      unless new_node.tickets[url_template] == old_node.tickets[url_template]
        old_node.history = true
        old_node.save!
        ids_summary = Array.new
        new_node.tickets.each do |key, ids|
          next if key == "ids_summary"
          ids_summary += ids
        end
        new_node.tickets["ids_summary"] = ids_summary.uniq.sort.join(", ")
        new_node.save!
      end
    end
    render plain: OK_RESPONSE and return
  end
end
