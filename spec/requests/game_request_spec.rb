require 'rails_helper'

RSpec.describe 'Games', type: :request do
  describe :create do
    it 'creates a new game of the given size and number of mines' do
      expect {
        post "/games", params: { height: 6, width: 5, mines: 9 }
      }.to change(Game, :count).by(1)

      game_id = JSON.parse(response.body)["id"]
      new_game = Game.find(game_id)
      expect(response.status).to eq 200
      expect(new_game.height).to eq(6)
      expect(new_game.width).to eq(5)
      expect(new_game.mines.sum { |position| position.size }).to eq(9)
      expect(new_game.cells.sum { |_, v| v.size }).to eq(30)
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
        end
      end

      it_behaves_like 'returns a 400 response when a param is invalid', 'height', { width: 5, mines: 0 }
      it_behaves_like 'returns a 400 response when a param is invalid', 'width', { height: 10, mines: 0 }
      it_behaves_like 'returns a 400 response when a param is invalid', 'mines', { height: 10, width: 5, mines: 0 }
    end
  end

  describe :update do
    let(:game) do
      game = Game.generate(height: 4, width: 5, mines: 8)
      game.save!
      game
    end

    it 'updates the given cell of the given game' do
      put "/games", params: { id: game.id, x: 4, y: 3, command: 'uncover' }

      updated_game = Game.find(game.id)
      expect(response.status).to eq 200
      expect(updated_game.cell(4, 3)).to_not be_covered
    end

    it 'updates the given cell with a red flag' do
      put "/games", params: { id: game.id, x: 1, y: 2, command: 'red_flag' }

      updated_game = Game.find(game.id)
      expect(response.status).to eq 200
      expect(updated_game.cell(1, 2).flag).to eq Cell::RED_FLAG
    end

    it 'updates the given cell with a question mark flag' do
      put "/games", params: { id: game.id, x: 1, y: 2, command: 'question_mark' }

      updated_game = Game.find(game.id)
      expect(response.status).to eq 200
      expect(updated_game.cell(1, 2).flag).to eq Cell::QUESTION_MARK_FLAG
    end

    context 'validations' do
      it 'returns a 404 error when the game does not exist' do
        put "/games", params: { id: "something", x: 3, y: 4 }

        errors = JSON.parse(response.body)["errors"]
        error = errors[0]
        expect(response.status).to eq 404
        expect(errors.size).to eq 1
        expect(error['detail']).to eq "Couldn't find Game with 'id'=something"
      end

      it 'returns a 404 error when the given command is invalid' do
        put "/games", params: { id: game.id, x: 3, y: 4, command: 'invalid' }

        errors = JSON.parse(response.body)["errors"]
        error = errors[0]
        expect(response.status).to eq 400
        expect(errors.size).to eq 1
        expect(error['detail']).to eq "Invalid game command 'invalid'"
      end

      shared_examples 'returns a 400 response when a param is invalid' do |param_name, request_params|
        it "returns a 400 response when #{param_name} is invalid" do
          put "/games", params: request_params.merge(id: game.id)

          errors = JSON.parse(response.body)["errors"]
          error = errors[0]
          expect(response.status).to eq 400
          expect(errors.size).to eq 1
          expect(error['detail']).to eq "The given cell coordinate does not exist (#{request_params[:x]}, #{request_params[:y]})"
        end
      end

      it_behaves_like 'returns a 400 response when a param is invalid', 'height', { x: 100, y: 4, command: 'red_flag' }
      it_behaves_like 'returns a 400 response when a param is invalid', 'width', { x: 3, y: 400, command: 'uncover' }
    end
  end
end
