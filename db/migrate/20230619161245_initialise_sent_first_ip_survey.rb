class InitialiseSentFirstIpSurvey < ActiveRecord::Migration[6.1]
  def up
    sql = <<~SQL
      Select u.id, u.name, count(i.id) as count from users u
        left join memberships m on u.id = m.user_id
        left join organisations o on m.organisation_id = o.id
        left join locations l on l.organisation_id = o.id
        left join ips i on i.location_id = l.id group by u.id
    SQL

    result_list = ActiveRecord::Base.connection.exec_query(sql)
    result_list.each do |result|
      sent_first_ip_survey = result["count"].zero? ? 0 : 1
      sql = "update users set sent_first_ip_survey = #{sent_first_ip_survey} where id=#{result['id']}"
      ActiveRecord::Base.connection.exec_query(sql)
    end
  end
end
