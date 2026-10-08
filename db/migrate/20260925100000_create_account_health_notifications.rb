class CreateAccountHealthNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :account_health_notifications do |t|
      t.references :organisation, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :issue, null: false
      # Set while open and cleared on resolve, so the unique index allows one open row per issue.
      t.string :open_key
      t.datetime :detected_at, null: false
      t.datetime :resolved_at
      t.datetime :uncontactable_at
      t.timestamps
      t.index :open_key, unique: true
      t.index %i[organisation_id issue], name: "index_account_health_notifications_on_organisation_and_issue"
    end

    create_table :account_health_notification_recipients do |t|
      t.references :account_health_notification, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :email_address, null: false
      t.datetime :sent_at
      t.integer :attempts, null: false, default: 0
      t.string :last_error
      t.timestamps
      t.index %i[account_health_notification_id email_address],
              unique: true,
              name: "index_account_health_recipients_on_notification_and_email"
    end
  end
end
