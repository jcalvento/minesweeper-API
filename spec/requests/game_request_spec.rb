require 'rails_helper'


RSpec.describe 'Games', type: :request do
  describe :create do
    it 'creates a new game of the given size and number of mines' do
      expect {
        post "/games", params: { height: 6, width: 5, mines: 9 }
      }.to change(Game, :count).by(1)

      game_id = json_body["id"]
      new_game = Game.find(game_id)
      expect(response.status).to eq 200
      expect(new_game.height).to eq(6)
      expect(new_game.width).to eq(5)
      expect(new_game.mines.sum { |position| position.size }).to eq(9)
      expect(new_game.cells.sum { |_, v| v.size }).to eq(30)
      expect(new_game.mines_flagged).to eq(0)
      expect(new_game.uncovered_cells).to eq(0)
      expect(new_game).to_not be_ended
      expect(new_game.result).to be_nil
      assert_response_includes_game_fields(json_body, new_game)
    end

    context 'validations' do
      shared_examples 'returns a 400 response when a param is invalid' do |param_name, request_params|
        it "returns a 400 response when #{param_name} is missing" do
          expect {
            post "/games", params: request_params
          }.to_not change(Game, :count)

          errors = json_body["errors"]
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
      game = Game.generate(height: 4, width: 5, mines: 1)
      game.save!
      game
    end

    before { allow(Game).to receive(:mine_position).and_return 0 }

    it 'updates the given cell of the given game' do
      put "/games/#{game.id}", params: { x: 4, y: 3, command: 'uncover' }

      updated_game = Game.find(game.id)
      expect(response.status).to eq 200
      expect(updated_game.cell(4, 3)).to_not be_covered
      assert_response_includes_game_fields(json_body, updated_game)
    end

    it 'updates the given cell with a red flag' do
      put "/games/#{game.id}", params: { x: 1, y: 2, command: 'red_flag' }

      updated_game = Game.find(game.id)
      expect(response.status).to eq 200
      expect(updated_game.cell(1, 2).flag).to eq Cell::RED_FLAG
      assert_response_includes_game_fields(json_body, updated_game)
    end

    it 'updates the given cell with a question mark flag' do
      put "/games/#{game.id}", params: { x: 1, y: 2, command: 'question_mark' }

      updated_game = Game.find(game.id)
      expect(response.status).to eq 200
      expect(updated_game.cell(1, 2).flag).to eq Cell::QUESTION_MARK_FLAG
      assert_response_includes_game_fields(json_body, updated_game)
    end

    context 'when the game is already ended' do
      let(:ended_game) do
        game = Game.generate(height: 1, width: 1, mines: 1)
        game.red_flag 0, 0
        game.save!
        game
      end

      it 'does not allow any update' do
        put "/games/#{ended_game.id}", params: { x: 0, y: 0, command: 'delete_flag' }

        errors = json_body["errors"]
        error = errors[0]
        expect(response.status).to eq 400
        expect(errors.size).to eq 1
        expect(error['detail']).to eq 'Ended games cannot be updated'
      end
    end

    context 'validations' do
      it 'returns a 404 error when the game does not exist' do
        put "/games/something", params: { x: 3, y: 4 }

        errors = json_body["errors"]
        error = errors[0]
        expect(response.status).to eq 404
        expect(errors.size).to eq 1
        expect(error['detail']).to eq "Couldn't find Game with 'id'=something"
      end

      it 'returns a 404 error when the given command is invalid' do
        put "/games/#{game.id}", params: { x: 3, y: 4, command: 'invalid' }

        errors = json_body["errors"]
        error = errors[0]
        expect(response.status).to eq 400
        expect(errors.size).to eq 1
        expect(error['detail']).to eq "Invalid game command 'invalid'"
      end

      shared_examples 'returns a 400 response when a param is invalid' do |param_name, request_params|
        it "returns a 400 response when #{param_name} is invalid" do
          put "/games/#{game.id}", params: request_params

          errors = json_body["errors"]
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

  describe :index do
    it 'returns the list of existing games' do
      game = Game.generate(height: 2, width: 3, mines: 3)
      game.save!
      another_game = Game.generate(height: 2, width: 3, mines: 3)
      another_game.save!

      get '/games'

      expect(response.status).to eq 200
      expect(json_body).to eq([{id: game.id},  {id: another_game.id}].as_json)
    end
  end

  describe :show do
    it 'return the given game' do
      game = Game.generate(height: 2, width: 3, mines: 2)
      game.save!

      get "/games/#{game.id}"

      expect(response.status).to eq 200
      assert_response_includes_game_fields(json_body, game)
    end
  end

  context 'when the requested game does not exist' do
    it 'returns a 404 error' do
      get "/games/123"

      errors = json_body["errors"]
      error = errors[0]
      expect(response.status).to eq 404
      expect(error['detail']).to eq "Couldn't find Game with 'id'=123"
    end
  end
end

def json_body
  @json_body ||= JSON.parse(response.body)
end

def assert_response_includes_game_fields(json_response, game)
  expect(game.height).to eq(json_response['height'])
  expect(game.width).to eq(json_response['width'])
  expect(game.mines_flagged).to eq(json_response['mines_flagged'])
  expect(game.uncovered_cells).to eq(json_response['uncovered_cells'])
  expect(game.ended?).to eq(json_response['ended'])
  expect(game.result).to eq(json_response['result'])
  expect(game.cells.as_json).to eq(json_response['cells'])
  expect(game.created_at.to_s(:iso8601)).to eq(ActiveSupport::TimeZone['UTC'].parse(json_response['created_at']).to_s(:iso8601))
end
