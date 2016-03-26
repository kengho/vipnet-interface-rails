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
    networks = Network.where("vipnet_network_id = ?", params[:vipnet_network_id])
    if networks.size == 0
      network = Network.new(vipnet_network_id: params[:vipnet_network_id])
      if network.save
        message.network_id = network.id
      else
        Rails.logger.error("Unable to save network")
        render plain: "error" and return
      end
    else
      message.network_id = networks.first.id
    end
    message.source = params[:source]
    if message.save
      render json: message.decode and return
    else
      Rails.logger.error("Unable to save message")
      render plain: "error" and return
    end
  end

end
