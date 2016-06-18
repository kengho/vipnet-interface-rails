class Api::V1::MessagesController < Api::V1::BaseController
  def create
    unless (params[:event_name] && params[:datetime])
      Rails.logger.error("Incorrect params '#{params}'")
      render plain: ERROR_RESPONSE and return
    end
    gotten_datetime = params[:datetime].to_i
    if gotten_datetime != 0
      time = Time.at(params[:datetime].to_i)
      datetime = time.to_datetime
    else
      Rails.logger.error("Unable to read datetime '#{params[:datetime]}'")
      render plain: ERROR_RESPONSE and return
    end

    if params[:event_name] == "DelUN"
      vipnet_id = VipnetParser::id(params[:vipnet_id])
      current_node = Node.find_by(vipnet_id: vipnet_id, history: false)
      if current_node
        new_node = current_node.dup
        current_node.history = true
        new_node.deleted_at = datetime
        render plain: ERROR_RESPONSE and return unless current_node.save! && new_node.save!
      end
    end

    render plain: OK_RESPONSE and return
  end
end
