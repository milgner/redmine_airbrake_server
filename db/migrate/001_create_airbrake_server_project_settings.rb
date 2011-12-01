class CreateAirbrakeServerProjectSettings < ActiveRecord::Migration
  def self.up
    create_table :airbrake_server_project_settings do |t|
      t.column :project_id, :integer
      t.column :fixed_version_id, :integer
      t.column :category_id, :integer
      t.column :assign_to_id, :integer
      t.column :author_id, :integer
      t.column :tracker_id, :integer
      t.column :reopen_strategy, :string
      t.column :priority_id, :integer
    end
  end

  def self.down
    drop_table :airbrake_server_project_settings
  end
end