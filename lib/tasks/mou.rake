namespace :mou do
  desc "Reset an organisation into re-signing the MOU (organisation specified by name)"
  task :resign, [:organisation_name] => :environment do |_task, args|
    organisation = Organisation.find_by!(name: args[:organisation_name])
    UseCases::Organisation::ResignMou.new(organisation_id: organisation.id).execute
    puts "MOU re-sign requested for #{organisation.name}"
  end
end
