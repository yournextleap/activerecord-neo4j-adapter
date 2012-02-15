module ActiveRecord
	class Migrator
   def get_all_versions
      table = Arel::Table.new(schema_migrations_table_name)
      Base.connection.select_values(table.project(table['version'])).map{ |v| v.to_i }.sort
    end
 end # Migration
end # ActiveRecord