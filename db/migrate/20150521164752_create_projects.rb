class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :source, null: false
      t.string :title, null: false
      t.string :url, null: false
      t.string :location
      t.boolean :has_started, default: true
      t.integer :funding_threshold
      t.integer :funding_limit
      t.integer :funding_current
      t.integer :investors_count

      t.timestamps null: false
    end
    add_index :projects, :url, unique: true
    add_index :projects, [:source, :title], unique: true
  end
end
