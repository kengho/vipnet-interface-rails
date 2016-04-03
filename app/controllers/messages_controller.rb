class MessagesController < ApplicationController
  def index
    p Message.all
    @messages = Message.all.paginate(page: params[:page], per_page: 50)
  end
end
