class Api::V1::MessagesController < Api::V1::BaseController

  def create
    unless (params[:message] && params[:source])
      Rails.logger.error("Incorrect params")
      render plain: "error" and return
    end
    incoming_message = params[:message]
    incoming_message = incoming_message.force_encoding("cp866").encode("utf-8", replace: nil)
    message = Message.new
    message.content = incoming_message
    network = Network.find_or_create_network(params[:vipnet_network_id])
    message.network_id = network.id
    message.source = params[:source]
    if message.save
      render json: message.decode and return
    else
      Rails.logger.error("Unable to save message")
      render plain: "error" and return
    end
  end

end
