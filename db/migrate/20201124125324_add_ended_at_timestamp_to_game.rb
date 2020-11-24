class AddEndedAtTimestampToGame < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :ended_at, :timestamp
  end
end
