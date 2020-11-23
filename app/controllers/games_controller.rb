class GamesController < ApplicationController
  def create
    begin
      new_game = Game.generate(height: params[:height].to_i, width: params[:width].to_i, mines: params[:mines].to_i)
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
    action = params[:command]

    update_cell(game, x, y, action)

    head :ok
  rescue ActiveRecord::RecordNotFound => e
    render_error e.message, :not_found
  rescue InvalidCellCoordinateError => e
    render_error e.message, :bad_request
  end

  private

  def update_cell(game, x, y, action)
    if action.to_s.eql? 'red_flag'
      game.red_flag x.to_i, y.to_i
    elsif action.to_s.eql? 'question_mark'
      game.question_mark_flag x.to_i, y.to_i
    elsif action.to_s.eql? 'uncover'
      game.uncover_cell x.to_i, y.to_i
    end
    game.save!
  end

  def render_error(message, status_code)
    render :json => {
      errors: [{ detail: message }]
    }, :status => status_code
  end
end
