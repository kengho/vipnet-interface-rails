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
    vid = ticket[:vid]
    id = ticket[:id]
    url_template = ticket[:url_template]

    ticket_system = TicketSystem.find_or_create_by(url_template: url_template)
    node = CurrentNode.find_by(vid: vid)
    if node
      ids = eval(node.ticket[url_template] || "\[\]")
      ids.push(id)
      ids = ids.uniq.sort
      node.ticket[url_template] = ids
      node.save!
    end
    render plain: OK_RESPONSE and return
  end
end
