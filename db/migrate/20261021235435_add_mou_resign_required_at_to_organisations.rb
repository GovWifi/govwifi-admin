class AddMouResignRequiredAtToOrganisations < ActiveRecord::Migration[8.0]
  def change
    add_column :organisations, :mou_resign_required_at, :datetime
  end
end
