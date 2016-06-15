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
      current_nodes = Node.where("vipnet_id = ? AND history = 'false'", vipnet_id)
      if current_nodes.size == 0
        # could happen if internetworking node dissapears from export, but it's not in database yet
        Rails.logger.warn("No nodes found '#{vipnet_id}'")
      elsif current_nodes.size == 1
        current_node = current_nodes.first
        new_node = current_node.dup
        current_node.history = true
        new_node.deleted_at = datetime
        render plain: ERROR_RESPONSE and return unless new_node.save! && current_node.save!
      elsif current_nodes.size > 1
        Rails.logger.error("Multiple nodes found '#{vipnet_id}'")
        render plain: ERROR_RESPONSE and return
      end
    end

    render plain: OK_RESPONSE and return
  end
end
