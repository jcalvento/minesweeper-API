class Game < ApplicationRecord
  MINE = "Mine".freeze
  serialize :cells
  validates :height, :width, presence: true, numericality: true

  def self.generate(height, width, mines)
    number_of_cells = height * width
    mines_positions = []
    mines.times do
      mines_positions << mine_position(mines_positions, number_of_cells)
    end
    cells = mines_positions.map do |position|
      x = position / width
      y = position % width
      {x: {y: MINE}}
    end

    Game.new(height: height, width: width, cells: cells)
  end

  def mines
    cells
  end

  private

  def self.mine_position(mines_positions, number_of_cells)
    position = rand(0..number_of_cells - 1)
    return mine_position(mines_positions, number_of_cells) if mines_positions.include? position

    position
  end
end
