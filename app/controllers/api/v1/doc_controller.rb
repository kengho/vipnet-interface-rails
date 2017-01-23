class Api::V1::DocController < ApplicationController
  skip_before_action :authenticate_user
end
