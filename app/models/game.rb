class Game < ApplicationRecord
  MINE = 'Mine'.freeze
  serialize :cells
  validates :height, :width, presence: true, numericality: true

  def self.validate_params(height, width, mines)
    if [height, width, mines].any? { |param| param <= 0 }
      raise InvalidGameParamError.new 'Height, width and number of mines must be greater than 0'
    end
  end

  def self.generate(height, width, mines)
    self.validate_params(height, width, mines)
    number_of_cells = height * width
    mines_positions = []
    mines.times do
      mines_positions << mine_position(mines_positions, number_of_cells)
    end
    cells = mines_positions.reduce({}) do |result, position|
      x = position / width
      y = position % width
      result[x] = {} unless result[x]
      result[x][y] = {mine: true}

      result
    end
    (0..number_of_cells-1).each do |index|
      x = index / width
      y = index % width
      next if cells.dig(x, y)

      cells[x] = {} unless cells[x]
      cells[x][y] = {mine: false}
    end

    Game.new(height: height, width: width, cells: cells)
  end

  def mines
    cells.map { |_, v| v.filter { |_, vv| vv[:mine] } }
  end

  private

  def self.mine_position(mines_positions, number_of_cells)
    position = rand(0..number_of_cells - 1)
    return mine_position(mines_positions, number_of_cells) if mines_positions.include? position

    position
  end
end

class InvalidGameParamError < RuntimeError; end