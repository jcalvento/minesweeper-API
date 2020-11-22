require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'validations' do
    it { should validate_presence_of :height }
    it { should validate_presence_of :width }
    it { should validate_numericality_of :height }
    it { should validate_numericality_of :width }
  end

  describe '.generate' do
    it 'creates the given number of cells and mines, all covered' do
      game = Game.generate(5, 7, 8)

      expect(game.mines.sum { |position| position.size }).to eq(8)
      expect(game.cells.sum { |_, v| v.size }).to eq(35)
      expect(game.cells.all? { |_, v| v.all? {|_, y_position| y_position[:covered] } }).to be true
    end
  end
end
