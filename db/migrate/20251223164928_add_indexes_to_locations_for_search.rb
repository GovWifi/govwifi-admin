class AddIndexesToLocationsForSearch < ActiveRecord::Migration[8.0]
  def change
    change_table :locations, bulk: true do |t|
      t.index :postcode
      t.index :address
    end
  end
end
