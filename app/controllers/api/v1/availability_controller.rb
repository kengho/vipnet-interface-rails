class Api::V1::AvailabilityController < Api::V1::BaseController
  def index
    render nothing: true, status: :unauthorized, content_type: "text/html" and return
  end
end
