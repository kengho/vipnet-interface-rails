class UpdateChannel < ApplicationCable::Channel
  def subscribed
    stream_from "update"
  end

  def self.push(json)
    ActionCable.server.broadcast("update", json)
  end
end
