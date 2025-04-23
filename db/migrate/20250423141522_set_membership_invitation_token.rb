class SetMembershipInvitationToken < ActiveRecord::Migration[7.0]
  sql = <<~SQL
    Select id as membership_id
      from memberships
        where invitation_token IS NULL
  SQL

  result_list = ActiveRecord::Base.connection.exec_query(sql)
  result_list.each do |result|
    invitation_token = Devise.friendly_token[0, 20]
    sql = "update memberships set invitation_token = \"#{invitation_token}\" where id=#{result['membership_id']}"
    ActiveRecord::Base.connection.exec_query(sql)
  end
end
