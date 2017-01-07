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
    ncc_node = CurrentNccNode.find_by(vid: vid)
    ticket_system = TicketSystem.find_or_create_by(url_template: url_template)
    Ticket.create!(
      ncc_node: ncc_node,
      ticket_system: ticket_system,
      vid: vid,
      ticket_id: id,
    )

    if minutes_after_latest_update("tickets") < 5
      UpdateChannel.push(update: true)
    end
    render plain: OK_RESPONSE and return
  end
end
