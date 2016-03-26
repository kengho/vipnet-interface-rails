class Message < ActiveRecord::Base
  belongs_to :network

  default_scope { order("created_at DESC") }

  # добавлена связь типов коллективов
  # 15.02.16 15:36:12 AddUC: 1A0E000D 1A0E000C
  # удалена связь типов коллективов
  # 15.02.16 16:10:15 DelUC: 1A0E000D 1A0E000C
  # USERCROS.DB

  # добавлен пользователь; test2 - имя пользователя; ID - номер пользователя
  # 15.02.16 17:47:12 AddAN: test2 ID=04AA0298 Sign=1
  # удален пользователь; ID - номер пользователя
  # 15.02.16 22:41:12 DelAN: test2 ID=04AA0298

  # заданы связи между АП, ТК и П; AN - номер пользователя; UG - номер коллектива; NO - номер АП
  # 15.02.16 17:47:12 AddUL: AN=04AA0298 UG=04AA02BA NO=04AA02C6
  # удалены связи между АП, ТК и П; AN - номер пользователя; UG - номер коллектива; NO - номер АП
  # 15.02.16 22:41:12 DelUL: AN=04AA0298 UG=04AA02BA NO=04AA02C6 R=1

  # что-то в NodeName.doc изменилось
  # 15.02.16 22:35:15 Create DB\NodeName 0
  CREATE_NODENAME_MESSAGE = "Create DB\\NodeName 0"
  CREATE_NODENAME_RESPONSE = "post nodename.doc"
  OK_RESPONSE = "ok"

  # удален узел; test2 - имя АП (не стоит доверять); UG - номер коллектива; NO - номер АП
  # 15.02.16 22:41:12 DelUN: test2 UG=04AA02BA NO=04AA02C6
  DELETE_NODE_MESSAGE = /DelUN: .*\sUG=[0-9A-F]{8}\sNO=(?<vipnet_id>[0-9A-F]{8})/

  # добавлен узел; test2 - имя узла; ID - номер коллектива; NO - номер АП
  # 15.02.16 17:47:12 AddUN: test2 ID=04AA02BA NO=04AA02C6
  CREATE_NODE_MESSAGE = /AddUN: .*\sID=[0-9A-F]{8}\sNO=(?<vipnet_id>[0-9A-F]{8})/

  def decode
    # meaningful messages looks like
    # |0 ..         16| |18 .. rest
    # 29.01.16 15:21:19 Create DB\NodeName 0
    message_regexp = /(?<datetime>\d\d\.\d\d\.\d\d\s\d\d:\d\d:\d\d)\s(?<event>.*)$/
    match = message_regexp.match(self.content)
    if match
      event = match["event"]
    else
      return OK_RESPONSE
    end

    if event == CREATE_NODENAME_MESSAGE
      return CREATE_NODENAME_RESPONSE
    end

    match_delete_node = DELETE_NODE_MESSAGE.match(event)

    if match_delete_node
      success = true
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
        unless new_node.save
          Rails.logger.error("Unable to save new_node")
          return "error"
        end
        unless current_node.save
          Rails.logger.error("Unable to save current_node")
          return "error"
        end
      elsif current_nodes.size > 1
        Rails.logger.error("Multiple nodes found '#{vipnet_id}'")
        return "error"
      end
      nodes_to_destroy.each do |node_to_destroy|
        node_to_destroy.deleted_by_message_id = self.id
        node_to_destroy.deleted_at = self.created_at
        unless node_to_destroy.save
          success = false
          break
        end
      end
      unless success
        Rails.logger.error("Unable to save node_to_destroy")
        return "error"
      end
      OK_RESPONSE
    end

    match_create_node = CREATE_NODE_MESSAGE.match(event)
    if match_create_node
      success = true
      created_nodes = Node.where("vipnet_id = '#{Node.normalize_vipnet_id(match_create_node[:vipnet_id])}'")
      created_nodes.each do |created_node|
        created_node.created_by_message_id = self.id
        unless created_node.save
          success = false
          break
        end
      end
      unless success
        Rails.logger.error("Unable to save created_node")
        return "error"
      end
      OK_RESPONSE
    end

    "ok"
  end

end
