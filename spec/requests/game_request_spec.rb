require 'rails_helper'

RSpec.describe "Games", type: :request do
  describe :create do
    it "creates a new game of the given size and number of mines" do
      expect {
        post "/games", params: { height: 6, width: 5, mines: 9}
      }.to change(Game, :count).by(1)

      game_id = JSON.parse(response.body)["id"]
      new_game = Game.find(game_id)
      expect(new_game.height).to eq(6)
      expect(new_game.width).to eq(5)
      expect(new_game.mines.count).to eq(9)
    end
  end
end
