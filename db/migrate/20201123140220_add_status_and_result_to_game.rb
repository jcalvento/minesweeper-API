class AddStatusAndResultToGame < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :ended, :boolean, default: false
    add_column :games, :result, :string
    add_column :games, :mines_flagged, :integer, default: 0
    add_column :games, :uncovered_cells, :integer, default: 0
  end
end
