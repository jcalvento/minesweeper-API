class Cell
  RED_FLAG = 'red_flag'.freeze
  QUESTION_MARK_FLAG = 'question_mark_flag'.freeze

  def initialize(mine:, covered:, near_mines_count:, flag:, game:, x:, y:)
    @mine = mine
    @covered = covered
    @near_mines_count = near_mines_count
    @flag = flag
    @game = game
    @x_position = x
    @y_position = y
  end

  attr_accessor :near_mines_count, :flag, :x_position, :y_position, :mine, :covered
  alias_method :mined?, :mine
  alias_method :covered?, :covered

  def red_flag
    updating_game { @flag = RED_FLAG }
  end

  def question_mark_flag
    updating_game { @flag = QUESTION_MARK_FLAG }
  end

  def delete_flag
    updating_game { @flag = nil }
  end

  def flagged?
    @flag.present?
  end

  def uncover
    updating_game do
      @covered = false

      @game.uncover_surroundings self.x_position, self.y_position
    end unless flagged?
  end

  private

  def updating_game(&block)
    block.call

    @game.update_cell self
  end
end