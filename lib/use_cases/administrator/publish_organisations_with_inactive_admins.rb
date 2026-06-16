require 'logger'

module UseCases
  module Administrator
    class PublishOrganisationsWithInactiveAdmins
      def publish
        logger = Logger.new($stdout)

        sql = "WITH OrganisationAdminStats AS (
                SELECT
                    o.name,
                    COUNT(u.email) AS total_admins,
                    SUM(
                        CASE
                            -- MySQL specific interval syntax:
                            WHEN u.last_sign_in_at >= CURRENT_DATE - INTERVAL 1 YEAR THEN 1
                            ELSE 0
                        END
                    ) AS active_admins
                FROM
                    users u
                INNER JOIN memberships m ON
                    u.id = m.user_id
                INNER JOIN organisations o ON
                    o.id = m.organisation_id
                WHERE
                    m.can_manage_locations = 1 AND m.can_manage_team = 1
                GROUP BY
                    o.name
            )
            SELECT
                COUNT(*) AS total_organisations,
                CURRENT_DATE AS run_date
            FROM
                OrganisationAdminStats
            WHERE
                total_admins < 2
                AND active_admins = 0;"
        orgs = ActiveRecord::Base.connection.execute(sql).to_a

        metric = {
          metric_name: "organisations_with_inactive_admins",
          count: orgs[0][0],
          run_time: Time.zone.today,
        }

        logger.info(metric.to_yaml)
        # Gateways::S3.new(**Gateways::S3::S3_METRICS_BUCKET).write(orgs.to_yaml)
      end
    end
  end
end
