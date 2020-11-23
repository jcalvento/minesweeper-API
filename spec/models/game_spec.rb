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
      game = Game.generate(height: 5, width: 7, mines: 8)

      expect(game.mines.sum { |position| position.size }).to eq(8)
      expect(game.cells.sum { |_, v| v.size }).to eq(35)
      expect(game.cells.all? { |_, v| v.all? {|_, y_position| y_position[:covered] } }).to be true
    end

    it 'when creating a new game, cells with adjacent mines have the number of mines nearby' do
      allow(Game).to receive(:mine_position).and_return 6, 7

      game = Game.generate(height: 4, width: 4, mines: 2)

      expect(game.cell(1, 0).near_mines_count).to eq 1
      expect(game.cell(3, 0).near_mines_count).to eq 2
      expect(game.cell(3, 0).near_mines_count).to eq 2
      expect(game.cell(1, 1).near_mines_count).to eq 1
      expect(game.cell(1, 2).near_mines_count).to eq 1
      expect(game.cell(2, 2).near_mines_count).to eq 2
      expect(game.cell(3, 2).near_mines_count).to eq 2
    end
  end

  describe '#uncover_cell' do
    let(:game) { Game.generate(height: 5, width: 5, mines: 8) }

    it 'marks the given cell as uncovered' do
      x, y = 0, 2

      game.uncover_cell x, y

      assert_is_uncovered(game, x, y)
    end

    context 'uncovering a mined cell' do
      let(:game) { Game.generate(height: 4, width: 3, mines: 3) }

      before { allow(Game).to receive(:mine_position).and_return 7, 8, 6 }

      it 'finished the game with a failed status' do
        expect { game.uncover_cell 0, 2 }.to change(game, :ended?).from(false).to(true).
          and change(game, :result).from(nil).to(Game::FAILED)
      end
    end

    context 'an already uncovered cell' do
      it 'when marking the cell as uncovered it leaves the same' do
        x, y = 0, 2
        game.uncover_cell x, y

        game.uncover_cell x, y

        assert_is_uncovered(game, x, y)
      end
    end

    context 'uncovering surrounding cells' do
      let(:game) { Game.generate(height: 4, width: 3, mines: 1) }

      before { allow(Game).to receive(:mine_position).and_return 7 }

      it 'when marking the cell as uncovered, all surrounding not mined cells will be uncovered' do
        game.uncover_cell 0, 0

        assert_is_uncovered(game, 0, 0)
        assert_is_uncovered(game, 0, 1)
        assert_is_uncovered(game, 1, 1)
        assert_is_uncovered(game, 1, 0)
        assert_is_uncovered(game, 2, 0)
        assert_is_covered(game, 0, 2)
        assert_is_covered(game, 1, 2)
        assert_is_covered(game, 2, 2)
        assert_is_covered(game, 0, 3)
        assert_is_covered(game, 1, 3)
        assert_is_covered(game, 2, 3)
      end

      context 'when a surrounding cell is marked' do
        it 'does not uncover it' do
          game.question_mark_flag 1, 0

          game.uncover_cell 0, 0

          assert_is_uncovered(game, 0, 0)
          assert_is_uncovered(game, 0, 1)
          assert_is_uncovered(game, 1, 1)
          assert_is_covered(game, 1, 0)
          assert_is_covered(game, 2, 0)
          assert_is_covered(game, 0, 2)
          assert_is_covered(game, 1, 2)
          assert_is_covered(game, 2, 2)
          assert_is_covered(game, 0, 3)
          assert_is_covered(game, 1, 3)
          assert_is_covered(game, 2, 3)
        end
      end

      context 'when the given cell has adjacent mines' do
        it 'does not uncover any other cell' do
          x, y = 0, 1
          game.uncover_cell x, y

          expect(game.cell(x, y).near_mines_count).to eq 1
          expect(game.cells.all? { |y_position, v|
            v.all? { |x_position, vv| y_position.eql?(y) && x_position.eql?(x) || vv[:covered] }
          }).to be true
        end
      end
    end
  end

  describe '#red_flag' do
    let(:game) { Game.generate(height: 3, width: 3, mines: 3) }

    it 'marks the given cell with a red flag' do
      x, y = 0, 1

      game.red_flag x, y

      expect(game.cell(x, y)).to be_flagged
    end

    it 'does not uncover the cell when there is a red flag on it' do
      x, y = 1, 1
      game.red_flag x, y

      game.uncover_cell x, y

      assert_is_covered(game, x, y)
    end
  end

  describe '#question_mark_flag' do
    let(:game) { Game.generate(height: 4, width: 3, mines: 2) }

    it 'marks the given cell with a question mark flag' do
      x, y = 2, 3

      game.question_mark_flag x, y

      expect(game.cell(x, y)).to be_flagged
    end

    it 'does not uncover the cell when there is a question mark flag on it' do
      x, y = 1, 1
      game.question_mark_flag x, y

      game.uncover_cell x, y

      assert_is_covered(game, x, y)
    end
  end

  describe '#delete_flag' do
    let(:game) { Game.generate(height: 2, width: 3, mines: 2) }

    it 'remove the current flag of the given cell' do
      x, y = 2, 1
      game.question_mark_flag x, y

      game.delete_flag x, y

      expect(game.cell(x, y)).to_not be_flagged
    end
  end

  describe 'ending game' do
    let(:game) { Game.generate(height: 3, width: 3, mines: 3) }

    before { allow(Game).to receive(:mine_position).and_return 7, 6, 8 }

    context 'uncovering the last cells' do
      it 'ends game with success result' do
        game.red_flag 0, 2
        game.red_flag 1, 2
        game.red_flag 2, 2

        expect{ game.uncover_cell 0, 0 }.to change(game, :ended?).from(false).to(true).
          and change(game, :result).from(nil).to(Game::SUCCESS)
      end
    end

    context 'red flag last mine' do
      it 'ends game with success result' do
        game.uncover_cell 0, 0
        game.red_flag 0, 2
        game.red_flag 1, 2

        expect{ game.red_flag 2, 2 }.to change(game, :ended?).from(false).to(true).
          and change(game, :result).from(nil).to(Game::SUCCESS)
      end
    end
  end
  def assert_is_uncovered(game, x, y)
    expect(game.cell(x, y)).to_not be_covered
  end

  def assert_is_covered(game, x, y)
    expect(game.cell(x, y)).to be_covered
  end
end
