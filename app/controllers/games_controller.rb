class GamesController < ApplicationController
  def create
    begin
      new_game = Game.generate(params[:height].to_i, params[:width].to_i, params[:mines].to_i)
      new_game.save!
    rescue InvalidGameParamError => e
      return render_error e.message, :bad_request
    end

    render :json => {id: new_game.id}
  end

  def update
    game = Game.find(params[:id])
    x = params[:x].to_i
    y = params[:y].to_i

    game.uncover_cell x.to_i, y.to_i

    game.save!

    head :ok
  rescue ActiveRecord::RecordNotFound => e
    render_error e.message, :not_found
  rescue InvalidCellCoordinateError => e
    render_error e.message, :bad_request
  end

  private

  def render_error(message, status_code)
    render :json => {
      errors: [{ detail: message }]
    }, :status => status_code
  end
end
