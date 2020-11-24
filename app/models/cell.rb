class Cell
  RED_FLAG = 'red_flag'.freeze
  QUESTION_MARK_FLAG = 'question_mark_flag'.freeze

  def initialize(mine:, covered:, adjacent_mines_count:, flag:, game:, x:, y:)
    @mine = mine
    @covered = covered
    @adjacent_mines_count = adjacent_mines_count
    @flag = flag
    @game = game
    @x_position = x
    @y_position = y
  end

  attr_accessor :adjacent_mines_count, :flag, :x_position, :y_position, :mine, :covered
  alias_method :mined?, :mine
  alias_method :covered?, :covered

  def red_flag
    return if red_flagged?

    updating_game { @flag = RED_FLAG }

    @game.red_flagged_mined_cell if mined?
  end

  def question_mark_flag
    updating_red_flag { @flag = QUESTION_MARK_FLAG }
  end

  def delete_flag
    updating_red_flag { @flag = nil }
  end

  def flagged?
    @flag.present?
  end

  def uncover
    unless flagged? || !covered?
      updating_game { @covered = false }

      return @game.end_game_failed if mined?

      @game.uncovered_cell

      @game.uncover_surroundings self.x_position, self.y_position unless has_adjacent_mines?
    end
  end

  def has_adjacent_mines?
    adjacent_mines_count > 0
  end

  private

  def updating_red_flag(&block)
    current_flag = @flag
    updating_game &block

    @game.deleted_red_flag if red_flagged?(current_flag) and mined?
  end

  def red_flagged?(current_flag=@flag)
    current_flag == RED_FLAG
  end

  def updating_game
    yield

    @game.update_cell self
  end
end