# frozen_string_literal: true

# Work-around for a MySQL + Rails schema-load ordering problem.
#
# Rails' `db:schema:load` emits `CREATE TABLE ... ; DROP TABLE IF EXISTS ...`
# statements in the order tables appear in db/schema.rb. MySQL refuses to DROP
# a table that another table still references through a foreign key (e.g.
# active_storage_variant_records -> active_storage_blobs), so loading the schema
# aborts with:
#
#   Mysql2::Error: Cannot drop table 'active_storage_blobs' referenced by a
#   foreign key constraint 'fk_rails_...' on table 'active_storage_variant_records'.
#
# We suspend MySQL's foreign-key checks for the duration of the schema load and
# restore them afterwards. This lets db/schema.rb be loaded verbatim, without
# editing it. We override ActiveRecord::Tasks::DatabaseTasks#load_schema (rather
# than shadowing the db:schema:load rake task) so the work-around applies no
# matter how rake orders task definitions. load_schema runs with
# ActiveRecord::Base.connection bound to the connection actually used for the
# CREATE/DROP statements, so suspending the checks here targets exactly that
# connection.

module ActiveRecord
  module Tasks
    module DatabaseTasks
      alias_method :load_schema_without_fk_suspension, :load_schema

      def load_schema(db_config, format = db_config.schema_format, file = nil) # :nodoc:
        ActiveRecord::Base.connection.exec_query("SET FOREIGN_KEY_CHECKS=0")
        begin
          load_schema_without_fk_suspension(db_config, format, file)
        ensure
          ActiveRecord::Base.connection.exec_query("SET FOREIGN_KEY_CHECKS=1")
        end
      end
    end
  end
end
