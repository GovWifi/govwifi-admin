class AddForeignKeyToIps < ActiveRecord::Migration[8.0]
  def change
    change_column_null :ips, :location_id, false
    add_foreign_key :ips, :locations, on_delete: :cascade
  end
end
