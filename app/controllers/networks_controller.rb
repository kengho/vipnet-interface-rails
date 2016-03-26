class NetworksController < ApplicationController
  def index
    @networks = Network.all
  end
end
