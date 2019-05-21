class CreateMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :memberships do |t|
      t.timestamps
      t.references :organisation, null: false
      t.string :invitation_token, null: false
      t.references :user, null: false
      t.integer :invited_by_id, null: false
    end
  end
end
