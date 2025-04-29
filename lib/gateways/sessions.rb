module Gateways
  class Sessions
    MAXIMUM_RESULTS_COUNT = 500
    SESSION_SELECT_ATTRIBUTES = %i[id start username siteIP success ap mac task_id cert_serial].freeze

    def self.search(username: nil, ips: nil, success: nil, authentication_method: nil)
      new.search(username:, ips:, success:, authentication_method:)
    end

    def search(username: nil, ips: nil, success: nil, authentication_method: nil)
      results = Session
      .select(SESSION_SELECT_ATTRIBUTES)
      .where("start >= ?", 2.weeks.ago)
      .order(id: :desc)
      .limit(MAXIMUM_RESULTS_COUNT)

      results = results.where(username:) unless username.nil?
      results = results.where(siteIP: ips) unless ips.nil?
      results = results.where(success:) if success.present?
      if authentication_method.present?
        results = if authentication_method == "true"
                    results.where(username: nil)
                  else
                    results.where.not(username: nil)
                  end
      end
      results
    end

    def self.organisation_usage_stats
      sql = "select datediff(min(i.created_at), o.created_at) as diff
      from organisations o join locations l on o.id=l.organisation_id join ips i on l.id=i.location_id group by o.name, o.created_at order by diff"
      arr = ActiveRecord::Base.connection.execute(sql).to_a
      flattened_arr = arr.flatten
      if flattened_arr.length.positive? && flattened_arr.length.odd?
        flattened_arr[flattened_arr.length / 2]
      elsif flattened_arr.length.positive? && flattened_arr.length.even?
        (flattened_arr[flattened_arr.length / 2 - 1] + flattened_arr[flattened_arr.length / 2]) / 2.0
      else
        0
      end
    end
  end
end
