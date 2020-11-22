require 'rails_helper'

RSpec.describe 'Games', type: :request do
  describe :create do
    it 'creates a new game of the given size and number of mines' do
      expect {
        post "/games", params: { height: 6, width: 5, mines: 9 }
      }.to change(Game, :count).by(1)

      game_id = JSON.parse(response.body)["id"]
      new_game = Game.find(game_id)
      expect(new_game.height).to eq(6)
      expect(new_game.width).to eq(5)
      expect(new_game.mines.sum { |position| position.values.count }).to eq(9)
      expect(new_game.cells.sum { |_, v| v.sum {|_, y_position| y_position.values.count } }).to eq(30)
    end

    context 'validations' do
      shared_examples 'returns a 400 response when a param is invalid' do |param_name, request_params|
        it "returns a 400 response when #{param_name} is missing" do
          expect {
            post "/games", params: request_params
          }.to_not change(Game, :count)

          errors = JSON.parse(response.body)["errors"]
          error = errors[0]
          expect(response.status).to eq 400
          expect(errors.size).to eq 1
          expect(error['detail']).to eq 'Height, width and number of mines must be greater than 0'
          expect(error['title']).to eq 'Invalid game param'
        end
      end

      it_behaves_like 'returns a 400 response when a param is invalid', 'height', { width: 5, mines: 0 }
      it_behaves_like 'returns a 400 response when a param is invalid', 'width', { height: 10, mines: 0 }
      it_behaves_like 'returns a 400 response when a param is invalid', 'mines', { height: 10, width: 5, mines: 0 }
    end
  end
end
