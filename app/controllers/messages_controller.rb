class MessagesController < ApplicationController
  def index
	p Settings.support_email
#    @messages = Message.all.paginate(page: params[:page], per_page: 50)
  end
end
