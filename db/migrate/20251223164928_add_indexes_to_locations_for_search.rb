class AddIndexesToLocationsForSearch < ActiveRecord::Migration[8.0]
  def change
    add_index :locations, :postcode
    add_index :locations, :address
  end
end
