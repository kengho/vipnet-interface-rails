class Api::V1::MessagesController < Api::V1::BaseController
  def create
    unless (params[:message] && params[:source] && params[:vipnet_network_id])
      Rails.logger.error("Incorrect params")
      render plain: "error" and return
    end

    incoming_message_raw = params[:message]
    incoming_message = incoming_message_raw.force_encoding("cp866").encode("utf-8", replace: nil)
    network = Network.find_or_create_network(params[:vipnet_network_id])
    message = Message.new(content: incoming_message, network_id: network.id, source: params[:source])
    if message.save
      render json: message.decode and return
    else
      render plain: "error" and return
    end
  end
end
