class ConfirmExistingMemberships < ActiveRecord::Migration[7.0]
  sql = <<~SQL
    Select m.id as membership_id
      from memberships m, users u
      where u.id=m.user_id and
        m.confirmed_at IS NULL and
        u.last_sign_in_at IS NOT NULL
  SQL

  result_list = ActiveRecord::Base.connection.exec_query(sql)
  result_list.each do |result|
    sql = "update memberships set confirmed_at = \"#{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')}\" where id=#{result['membership_id']}"
    ActiveRecord::Base.connection.exec_query(sql)
  end
end
