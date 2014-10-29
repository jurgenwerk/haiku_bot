class HaikusController < ApplicationController

  def index
    @haikus = Haiku.where(published: false, :created_at.gte => (DateTime.current - 1.day))
    binding.pry
  end

  def update
  end
end
