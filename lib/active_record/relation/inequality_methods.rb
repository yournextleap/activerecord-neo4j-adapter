require 'active_record/relation/inequality_builder'

module ActiveRecord
  module InequalityMethods
    extend ActiveSupport::Concern

    def lt(options)
      build_relation options, "<"
    end #lt

    def gt(options)
      build_relation options, ">"
    end #gt

    def leq(options)
      build_relation options, "<="
    end #leq

    def geq(options)
      build_relation options, ">="
    end #geq

    private
    def build_relation(inequalities, operand)
      relation = clone
      relation.where_values += build_inequality(inequalities, operand) if inequalities
      relation
    end

    def build_inequality(inequalities, operand)
      ActiveRecord::InequalityBuilder.new(table).build_from_hash inequalities, operand, table
    end
  end #InequalityMethods
end #ActiveRecord

ActiveRecord::Relation.send :include, ActiveRecord::InequalityMethods
