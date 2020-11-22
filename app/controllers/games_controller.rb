class GamesController < ApplicationController
  def create
    new_game = Game.generate(params[:height].to_i, params[:width].to_i, params[:mines].to_i)
    new_game.save!

    render :json => {id: new_game.id}
  end
end
