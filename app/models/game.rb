class Game < ApplicationRecord
  RED_FLAG = 'red_flag'.freeze
  QUESTION_MARK_FLAG = 'question_mark_flag'.freeze
  serialize :cells
  validates :height, :width, presence: true, numericality: true

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
      result[x][y] = { mine: false, covered: true, near_mines_count: 0 }
      result
    end
    cells = add_mines(mines, number_of_cells, width, height, cells)

    Game.new(height: height, width: width, cells: cells)
  end

  def mines
    cells.map { |_, v| v.filter { |_, vv| vv[:mine] } }
  end

  def uncover_cell(x, y)
    cell = cell(x, y)
    return if cell[:flag]
    raise InvalidCellCoordinateError.new "The given cell coordinate does not exist (#{x}, #{y})" unless cell

    cell[:covered] = false

    uncover_surroundings(x, y)
  end

  def cell(x, y)
    cells.dig(y, x)
  end

  def red_flag(x, y)
    cell(x, y)[:flag] = RED_FLAG
  end

  def question_mark_flag(x, y)
    cell(x, y)[:flag] = QUESTION_MARK_FLAG
  end

  def delete_flag(x, y)
    cell(x, y).delete :flag
  end

  private

  def uncover_surroundings(x, y)
    surroundings = self.class.surrounding_coordinates(height, width, x, y)
    surroundings.each do |coordinate|
      cell = cells[coordinate[0]][coordinate[1]]
      next if cell[:mine] || !cell[:covered]

      cell[:covered] = false

      uncover_surroundings coordinate[1], coordinate[0] unless cell[:near_mines_count] > 0
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
        cells[coordinate[0]][coordinate[1]][:near_mines_count] += 1
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