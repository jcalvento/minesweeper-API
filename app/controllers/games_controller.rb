class GamesController < ApplicationController
  def create
    begin
      new_game = Game.generate(params[:height].to_i, params[:width].to_i, params[:mines].to_i)
      new_game.save!
    rescue InvalidGameParamError => e
      return render :json => {
        errors: [{ title: 'Invalid game param', detail: e.message }]
      }, :status => :bad_request
    end

    render :json => {id: new_game.id}
  end
end
