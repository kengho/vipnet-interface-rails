class Message < ActiveRecord::Base
  belongs_to :network
  default_scope { order(created_at: :desc) }

  # UNPROCESSED MEANINGFUL MESSAGES

  # collectives types link added
  # 01.01.00 00:00:00 AddUC: 1A0E000D 1A0E000C
  # collectives types link deleted
  # 01.01.00 00:00:00 DelUC: 1A0E000D 1A0E000C
  # see USERCROS.DB

  # user added; client1 - username; ID - user id
  # 01.01.00 00:00:00 AddAN: client1 ID=1A0E1234 Sign=1
  # user deleted; client1 - username; ID - user id
  # 01.01.00 00:00:00 DelAN: client1 ID=1A0E1234

  # node, collective and user linked; AN - user number; UG - collective number; NO - node number
  # 01.01.00 00:00:00 AddUL: AN=1A0E1234 UG=1A0E1235 NO=1A0E1236
  # node, collective and user unlinked; AN - user number; UG - collective number; NO - node number
  # 01.01.00 00:00:00 DelUL: AN=1A0E1234 UG=1A0E1235 NO=1A0E1236

  # PROCESSED MESSAGES

  # NodeName.doc changed
  # 01.01.00 00:00:00 Create DB\NodeName 0
  CREATE_NODENAME_MESSAGE = "Create DB\\NodeName 0"
  CREATE_NODENAME_RESPONSE = "post nodename.doc"
  OK_RESPONSE = "ok"

  # node deleted; client1 - node name (should be ignored); UG - collective number; NO - node number
  # 01.01.00 00:00:00 DelUN: client1 UG=1A0E1235 NO=1A0E1236
  DELETE_NODE_MESSAGE = /DelUN: .*\sUG=[0-9A-F]{8}\sNO=(?<vipnet_id>[0-9A-F]{8})/

  # node added; client1 - node name; UG - collective number; NO - node number
  # 01.01.00 00:00:00 AddUN: client1 UG=1A0E1235 NO=1A0E1236
  CREATE_NODE_MESSAGE = /AddUN: .*\sID=[0-9A-F]{8}\sNO=(?<vipnet_id>[0-9A-F]{8})/

  def decode
    # meaningful messages looks like
    # |0 ..         16| |18 .. rest
    # 01.01.00 00:00:00 Create DB\NodeName 0
    message_regexp = /(?<datetime>\d\d\.\d\d\.\d\d\s\d\d:\d\d:\d\d)\s(?<event>.*)$/
    match = message_regexp.match(self.content)
    if match
      event = match["event"]
    else
      return OK_RESPONSE
    end

    return CREATE_NODENAME_RESPONSE if event == CREATE_NODENAME_MESSAGE

    match_delete_node = DELETE_NODE_MESSAGE.match(event)
    if match_delete_node
      vipnet_id = match_delete_node[:vipnet_id]
      nodes_to_destroy = Node.where("vipnet_id = ?", Node.normalize_vipnet_id(vipnet_id))
      current_nodes = nodes_to_destroy.where("history = 'false'")
      if current_nodes.size == 0
        # could happen if internetworking node dissapears from export, but it's not in database yet
        Rails.logger.warn("No nodes found '#{vipnet_id}'")
        return OK_RESPONSE
      elsif current_nodes.size == 1
        current_node = current_nodes.first
        new_node = current_node.dup
        current_node.history = true
        return "error" unless new_node.save!
        return "error" unless current_node.save!
      elsif current_nodes.size > 1
        Rails.logger.error("Multiple nodes found '#{vipnet_id}'")
        return "error"
      end
      success = true
      nodes_to_destroy.each do |node_to_destroy|
        node_to_destroy.deleted_by_message_id = self.id
        node_to_destroy.deleted_at = self.created_at
        unless node_to_destroy.save!
          Rails.logger.error("Error saving one of node_to_destroy (message_id #{self.id})")
          success = false
          break
        end
      end
      return "error" unless success
      return OK_RESPONSE
    end

    match_create_node = CREATE_NODE_MESSAGE.match(event)
    if match_create_node
      success = true
      created_nodes = Node.where("vipnet_id = ?", Node.normalize_vipnet_id(match_create_node[:vipnet_id]))
      created_nodes.each do |created_node|
        created_node.created_by_message_id = self.id
        unless created_node.save!
          Rails.logger.error("Error saving one of created_node (message_id #{self.id})")
          success = false
          break
        end
      end
      return "error" unless success
      return OK_RESPONSE
    end

    OK_RESPONSE
  end

end
