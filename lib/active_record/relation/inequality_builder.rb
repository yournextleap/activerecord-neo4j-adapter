require 'arel/nodes/inequality'

module ActiveRecord
  class InequalityBuilder

    def initialize(engine)
      @engine = engine
    end

    def build_from_hash(attributes, operand, default_table)
      inequalities = attributes.map do |column, value|
        table = default_table

        if value.is_a?(Hash)
          table = Arel::Table.new(column, :engine => @engine)
          build_from_hash(value, table)
        else
          column = column.to_s

          if column.include?('.')
            table_name, column = column.split('.', 2)
            table = Arel::Table.new(table_name, :engine => @engine)
          end

          attribute = table[column] || Arel::Attribute.new(table, column)

#          case value
#          when Array, ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation
#            values = value.to_a.map { |x|
#              x.is_a?(ActiveRecord::Base) ? x.id : x
#            }
#            attribute.in(values)
#          when Range, Arel::Relation
#            attribute.in(value)
#          when ActiveRecord::Base
#            attribute.eq(value.id)
#          when Class
#            # FIXME: I think we need to deprecate this behavior
#            attribute.eq(value.name)
#          else
            Arel::Nodes::Inequality.new attribute, value, operand
#          end
        end
      end

      inequalities.flatten
    end

  end
end
