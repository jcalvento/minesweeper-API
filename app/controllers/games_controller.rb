class GamesController < ApplicationController
  def index
    ids = Game.pluck(:id)

    render json: ids.map { |id| {id: id} }
  end

  def show
    game = Game.find(params[:id])

    render json: game.as_json
  rescue ActiveRecord::RecordNotFound => e
    return render_error e.message, :not_found
  end

  def create
    begin
      new_game = Game.generate(height: params[:height].to_i, width: params[:width].to_i, mines: params[:mines].to_i)

      new_game.save!
    rescue InvalidGameParamError => e
      return render_error e.message, :bad_request
    end

    render json: new_game.as_json
  end

  def update
    game = Game.find(params[:id])
    x, y = params[:x].to_i, params[:y].to_i

    GameCommand.for(params[:command].to_s, game, x, y).exec

    game.save!

    render json: game.as_json
  rescue ActiveRecord::RecordNotFound => e
    render_error e.message, :not_found
  rescue InvalidCellCoordinateError, InvalidCommandError, UpdateEndedGameError => e
    render_error e.message, :bad_request
  end

  private

  def render_error(message, status_code)
    render json: {
      errors: [{ detail: message }]
    }, status: status_code
  end
end
