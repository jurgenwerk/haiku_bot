class HaikusController < ApplicationController

  def index
    @haikus = Haiku.where(published: false, for_publishing: false, :created_at.gte => (DateTime.current - 1.day)).desc('_id').limit(200).to_a
  end

  def update
    haiku = Haiku.find(params[:id])

    if haiku
      haiku.for_publishing = true
      haiku.save
      render json: { status: "ok" }, status: 204
    else
      render json: { status: "error" }, status: 400
    end
  end
end
