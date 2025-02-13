namespace :cleanup do
  desc "Clean up inactive unconfirmed users"
  task unconfirmed: :environment do
    UseCases::DeleteInactiveUnconfirmed.execute(2.weeks)
  end
end
