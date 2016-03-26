class IplirconfsController < ApplicationController
  def index
    if params[:coordinator_id]
      @iplirconfs = Iplirconf.where("coordinator_id = ?", params[:coordinator_id])
    else
      @iplirconfs = Iplirconf.all
    end
  end

  def show
    if @iplirconf = Iplirconf.find_by_id(params[:id])
      if @coordinator = Coordinator.find_by_id(@iplirconf.coordinator_id)
        @content = @iplirconf.content
      else
        render plain: "Couldn't find Coordinator by id"
      end
    else
      render plain: "Couldn't find Iplirconf by id"
    end
  end
end
