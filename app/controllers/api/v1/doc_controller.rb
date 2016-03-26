class Api::V1::DocController < ApplicationController
  skip_before_action :authenticate_user
  skip_before_action :check_administrator_role

  def index
  end
end
