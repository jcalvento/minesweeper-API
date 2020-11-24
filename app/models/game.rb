class Game < ApplicationRecord
  serialize :cells
  validates :height, :width, presence: true, numericality: true

  FAILED = 'failed'.freeze
  SUCCESS = 'success'.freeze

  def self.validate_params(height, width, mines)
    if [height, width, mines].any? { |param| param <= 0 }
      raise InvalidGameParamError.new 'Height, width and number of mines must be greater than 0'
    end
  end

  def self.generate(height:, width:, mines:)
    self.validate_params(height, width, mines)
    number_of_cells = height * width
    cells = (0..number_of_cells-1).reduce({}) do |result, index|
      x = index / width
      y = index % width

      result[x] = {} unless result[x]
      result[x][y] = { mine: false, covered: true, adjacent_mines_count: 0, flag: nil }
      result
    end
    cells = add_mines(mines, number_of_cells, width, height, cells)

    Game.new(height: height, width: width, cells: cells)
  end

  def mines
    cells.map { |_, v| v.filter { |_, vv| vv[:mine] } }
  end

  def uncover_cell(x, y)
    validate_not_ended

    cell(x, y).uncover
  end

  def cell(x, y)
    cell = cells.dig(y, x)
    raise InvalidCellCoordinateError.new "The given cell coordinate does not exist (#{x}, #{y})" unless cell

    Cell.new game: self, x: x, y: y, **cell
  end

  def red_flag(x, y)
    validate_not_ended

    cell(x, y).red_flag
  end

  def question_mark_flag(x, y)
    validate_not_ended

    cell(x, y).question_mark_flag
  end

  def delete_flag(x, y)
    validate_not_ended

    cell(x, y).delete_flag
  end

  def update_cell(cell)
    cells[cell.y_position][cell.x_position].merge!({
      covered: cell.covered?,
      mine: cell.mined?,
      flag: cell.flag
    })
  end

  def uncover_surroundings(x, y)
    surroundings = self.class.surrounding_coordinates(height, width, x, y)
    surroundings.each do |coordinate|
      cell = cell(coordinate[1], coordinate[0])
      next if cell.mined?

      cell.uncover
    end
  end

  def red_flagged_mined_cell
    update_game_status { self.mines_flagged += 1 }
  end

  def uncovered_cell
    update_game_status { self.uncovered_cells += 1 }
  end

  def deleted_red_flag
    self.mines_flagged -= 1
  end

  def end_game_failed
    self.ended = true
    self.result = FAILED
  end

  private

  def validate_not_ended
    raise UpdateEndedGameError.new('Ended games cannot be updated') if ended?
  end

  def update_game_status
    yield

    cells_count = height * width
    mines_count = mines.count

    if self.mines_flagged.eql?(mines_count) && self.uncovered_cells.eql?(cells_count - mines_count)
      self.ended = true
      self.result = SUCCESS
    end
  end

  def self.add_mines(mines, number_of_cells, width, height, cells)
    mines_positions = []
    mines.times do
      mines_positions << mine_position(mines_positions, number_of_cells)
    end
    mines_positions.each do |position|
      y = position / width
      x = position % width
      cells[y][x][:mine] = true

      surroundings = surrounding_coordinates(height, width, x, y)
      surroundings.each do |coordinate|
        cells[coordinate[0]][coordinate[1]][:adjacent_mines_count] += 1
      end
    end

    cells
  end

  def self.surrounding_coordinates(height, width, x, y)
    prev_col, next_col = [0, x - 1].max, [width - 1, x + 1].min
    prev_row, next_row = [0, y - 1].max, [height - 1, y + 1].min

    Set[
      [prev_row, x], [prev_row, prev_col], [prev_row, next_col], [y, next_col],
      [y, prev_col], [next_row, x], [next_row, prev_col], [next_row, next_col]
    ]
  end

  def self.mine_position(mines_positions, number_of_cells)
    position = rand(0..number_of_cells - 1)
    return mine_position(mines_positions, number_of_cells) if mines_positions.include? position

    position
  end
end

class InvalidGameParamError < RuntimeError; end
class InvalidCellCoordinateError < RuntimeError; end
class UpdateEndedGameError < RuntimeError; end