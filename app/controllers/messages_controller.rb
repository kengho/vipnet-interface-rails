class MessagesController < ApplicationController
  def index
    @messages = Message.all.paginate(page: params[:page], per_page: 50)
  end
end
