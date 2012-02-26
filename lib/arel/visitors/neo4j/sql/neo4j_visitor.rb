module Arel
  module Visitors
    module Neo4j
      module Sql
        class Neo4jVisitor < Arel::Visitors::Visitor
          require 'arel/visitors/neo4j/response'
          def initialize engine
            @engine         = engine
            @connection     = nil
            @quoted_tables  = {}
            @quoted_columns = {}
          end

          def accept object
            self.last_column = nil
            @engine.connection_pool.with_connection do |conn|
              @connection = conn
              super
            end
          end

          private
          def visit_Arel_Nodes_DeleteStatement delete_statement
            model = visit delete_statement.relation
            query = [
                      "g",
                      "v(start_node)",
                      "out('instances')",
                      ("filter{#{delete_statement.wheres.map { |x| visit x }.join ' && ' }}" unless delete_statement.wheres.empty?),
                      "each{g.removeVertex(it)}"
                    ].join('.')
            #conditions = delete_statement.wheres.map {|where| visit where}.inject({}){|hash, next_item| hash.merge(next_item)}

            type = :delete
            deletions = {:model => model, :query => query}
            Arel::Visitors::Neo4j::Response.new type, :params => deletions
=begin
            [
              "DELETE FROM #{visit o.relation}",
              ("WHERE #{o.wheres.map { |x| visit x }.join ' AND '}" unless o.wheres.empty?)
            ].compact.join ' '
=end

          end

          def visit_Arel_Nodes_UpdateStatement o
            if o.orders.empty? && o.limit.nil?
              wheres = o.wheres
            else
              stmt             = Nodes::SelectStatement.new
              core             = stmt.cores.first
              core.froms       = o.relation
              core.projections = [o.relation.primary_key]
              stmt.limit       = o.limit
              stmt.orders      = o.orders

              wheres = [Nodes::In.new(o.relation.primary_key, [stmt])]
            end

            model = visit o.relation
            query = [
                      "g",
                      "v(start_node)",
                      "out('instances')",
                      ("filter{#{wheres.map { |x| visit x }.join ' && ' }}" unless wheres.empty?),
                      "each{#{o.values.map{|x| "it.#{visit x}"}.join(';')}}"
                    ].join('.')

            type = :update
            update = {:model => model, :query => query}
            Arel::Visitors::Neo4j::Response.new type, :params => update

=begin
            [
              "UPDATE #{visit o.relation}",
              ("SET #{o.values.map { |value| visit value }.join ', '}" unless o.values.empty?),
              ("WHERE #{wheres.map { |x| visit x }.join ' AND '}" unless wheres.empty?)
            ].compact.join ' '
=end

          end

          def visit_Arel_Nodes_InsertStatement insert_statement
            #insertions = {:model => visit(insert_statement.relation), :values => visit(insert_statement.values)}
            query = [
                      "g.addVertex(",
                      ("[#{visit(insert_statement.values)}]" unless insert_statement.columns.empty?),
                      ")"
                    ].join
            insertions = {:model => visit(insert_statement.relation), :query => query}
            type = :insert

            Arel::Visitors::Neo4j::Response.new type, :params => insertions

=begin
            [
              "INSERT INTO #{visit o.relation}",

              ("(#{o.columns.map { |x|
                    quote_column_name x.name
                }.join ', '})" unless o.columns.empty?),

              (visit o.values if o.values),
            ].compact.join ' '
=end

          end

          def visit_Arel_Nodes_Exists o
            "EXISTS (#{visit o.select_stmt})#{
              o.alias ? " AS #{visit o.alias}" : ''}"
          end

          def visit_Arel_Nodes_Values values
            values.expressions.zip(values.columns).map{|expression, column|\
                                                       ((visit(expression).present? and visit(expression) != 'null') ? "#{column.name.to_s} : #{visit expression}" : nil)\
                                                      }.compact.join(',')
            #values.expressions.zip(values.columns).map{|expression, column| {column.name => expression}}.inject({}){|h,i| h.merge(i)}
=begin
            "VALUES (#{o.expressions.zip(o.columns).map { |value, column|
              quote(value, column && column.column)
            }.join ', '})"
=end

          end

          def visit_Arel_Nodes_SelectStatement o
            #selections = o.cores.collect{|core| {:model => core.froms.name.to_sym, :attributes => core.projections.collect{|projection| projection.name}}}
            selections = o.cores.map{|core| {:model => core.froms.name.to_sym, :query => visit_Arel_Nodes_SelectCore(core)}}
            type = :select
            Arel::Visitors::Neo4j::Response.new type, :params => selections

            # SQL implementation for reference
=begin
            [
              o.cores.map { |x| visit_Arel_Nodes_SelectCore x }.join,
              ("ORDER BY #{o.orders.map { |x| visit x }.join(', ')}" unless o.orders.empty?),
              (visit(o.limit) if o.limit),
              (visit(o.offset) if o.offset),
              (visit(o.lock) if o.lock),
            ].compact.join ' '
=end

          end

          def visit_Arel_Nodes_SelectCore o
            [
              #"SELECT",
              #(visit(o.top) if o.top),
              #"#{o.projections.map { |x| visit x }.join ', '}",
              #("FROM #{visit o.froms}" if o.froms),
              "t = new Table();g",
              "v(start_node)",
              "out('instances')",
              ("filter{#{o.wheres.map { |x| visit x }.join ' && ' }}" unless o.wheres.empty?),
              "#{o.projections.map{|x| visit_As_Projection(x)}.join('.back(1).')}",
              "table(t, #{o.projections.map{|x| visit_Column_Projection(x)}.flatten.inspect})",
              "iterate();t;",
              #("WHERE #{o.wheres.map { |x| visit x }.join ' AND ' }" unless o.wheres.empty?),
              #("GROUP BY #{o.groups.map { |x| visit x }.join ', ' }" unless o.groups.empty?),
              #(visit(o.having) if o.having),
            #].compact.join ' '
            ].compact.join '.'
          end

          # Hack fix to convert table_name.* to Gremlin equivalent
          def visit_As_Projection o
            visited_value = visit(o).to_s

            if visited_value =~ /^.*(\.\*)$/
              "id.as(\"id\").back(1).map().as(\"properties\")"
            else
              "#{visited_value}.as(#{visited_value.inspect})"
            end
          end

          def visit_Column_Projection o
            visited_value = visit(o).to_s

            if visited_value =~ /^.*(\.\*)$/
              ["id","properties"]
            else
              visited_value
            end
          end

          def visit_Arel_Nodes_Having o
            "HAVING #{visit o.expr}"
          end

          def visit_Arel_Nodes_Offset o
            "OFFSET #{visit o.expr}"
          end

          def visit_Arel_Nodes_Limit o
            "LIMIT #{visit o.expr}"
          end

          # FIXME: this does nothing on most databases, but does on MSSQL
          def visit_Arel_Nodes_Top o
            ""
          end

          # FIXME: this does nothing on SQLLite3, but should do things on other
          # databases.
          def visit_Arel_Nodes_Lock o
          end

          def visit_Arel_Nodes_Grouping o
            "(#{visit o.expr})"
          end

          def visit_Arel_Nodes_Ordering o
            "#{visit o.expr} #{o.descending? ? 'DESC' : 'ASC'}"
          end

          def visit_Arel_Nodes_Group o
            visit o.expr
          end

          def visit_Arel_Nodes_Count o
            "count()"
=begin
            "COUNT(#{o.distinct ? 'DISTINCT ' : ''}#{o.expressions.map { |x|
              visit x
            }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
=end

          end

          def visit_Arel_Nodes_Sum o
            "SUM(#{o.expressions.map { |x|
              visit x }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
          end

          def visit_Arel_Nodes_Max o
            "MAX(#{o.expressions.map { |x|
              visit x }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
          end

          def visit_Arel_Nodes_Min o
            "MIN(#{o.expressions.map { |x|
              visit x }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
          end

          def visit_Arel_Nodes_Avg o
            "AVG(#{o.expressions.map { |x|
              visit x }.join(', ')})#{o.alias ? " AS #{visit o.alias}" : ''}"
          end

          def visit_Arel_Nodes_TableAlias o
            "#{visit o.relation} #{quote_table_name o.name}"
          end

          def visit_Arel_Nodes_Between o
            "#{visit o.left} BETWEEN #{visit o.right}"
          end

          def visit_Arel_Nodes_GreaterThanOrEqual o
            "#{visit o.left} >= #{visit o.right}"
          end

          def visit_Arel_Nodes_GreaterThan o
            "#{visit o.left} > #{visit o.right}"
          end

          def visit_Arel_Nodes_LessThanOrEqual o
            "#{visit o.left} <= #{visit o.right}"
          end

          def visit_Arel_Nodes_LessThan o
            "#{visit o.left} < #{visit o.right}"
          end

          def visit_Arel_Nodes_Matches o
            "#{visit o.left} LIKE #{visit o.right}"
          end

          def visit_Arel_Nodes_DoesNotMatch o
            "#{visit o.left} NOT LIKE #{visit o.right}"
          end

          def visit_Arel_Nodes_StringJoin o
            "#{visit o.left} #{visit o.right}"
          end

          def visit_Arel_Nodes_OuterJoin o
            "#{visit o.left} LEFT OUTER JOIN #{visit o.right} #{visit o.constraint}"
          end

          def visit_Arel_Nodes_InnerJoin o
            "#{visit o.left} INNER JOIN #{visit o.right} #{visit o.constraint if o.constraint}"
          end

          def visit_Arel_Nodes_On o
            "ON #{visit o.expr}"
          end

          def visit_Arel_Nodes_Not o
            "NOT (#{visit o.expr})"
          end

          def visit_Arel_Nodes_Union o
            "( #{visit o.left} UNION #{visit o.right} )"
          end

          def visit_Arel_Nodes_UnionAll o
            "( #{visit o.left} UNION ALL #{visit o.right} )"
          end

          def visit_Arel_Nodes_Intersect o
            "( #{visit o.left} INTERSECT #{visit o.right} )"
          end

          def visit_Arel_Nodes_Except o
            "( #{visit o.left} EXCEPT #{visit o.right} )"
          end

          def visit_Arel_Table o
            o.name
          end

          def visit_Arel_Nodes_In o
          "#{visit o.left} IN (#{visit o.right})"
          end

          def visit_Arel_Nodes_NotIn o
          "#{visit o.left} NOT IN (#{visit o.right})"
          end

          def visit_Arel_Nodes_And o
            "#{visit o.left} AND #{visit o.right}"
          end

          def visit_Arel_Nodes_Or o
            "#{visit o.left} OR #{visit o.right}"
          end

          def visit_Arel_Nodes_Assignment o
            right = quote(o.right, o.left.column)
            "#{visit o.left} = #{right}"
          end

          def visit_Arel_Nodes_Equality o
            right = o.right

            if right.nil?
              "!it.hasProperty(#{visit(o.left).to_s.inspect})"
              #{(visit o.left) => nil}
              #"#{visit o.left} IS NULL"
            else
              "it.#{visit(o.left).to_s} == #{visit o.right}"
              #{(visit o.left) => (visit o.right)}
              #"#{visit o.left} = #{visit right}"
            end
          end

          def visit_Arel_Nodes_NotEqual o
            right = o.right

            if right.nil?
              "it.hasProperty(#{visit(o.left).to_s.inspect})"
              #"#{visit o.left} IS NOT NULL"
            else
              "!#{Array.wrap(visit(o.right)).inspect}.contains(it.#{visit(o.left).to_s})"
              #"#{visit o.left} != #{visit right}"
            end
          end

          def visit_Arel_Nodes_As o
            "#{visit o.left} AS #{visit o.right}"
          end

          def visit_Arel_Nodes_UnqualifiedColumn o
            "#{quote_column_name o.name}"
          end

          def visit_Arel_Attributes_Attribute o
            self.last_column = o.column
            o.name
=begin
            join_name = o.relation.table_alias || o.relation.name
            "#{quote_table_name join_name}.#{quote_column_name o.name}"
=end

          end
          alias :visit_Arel_Attributes_Integer :visit_Arel_Attributes_Attribute
          alias :visit_Arel_Attributes_Float :visit_Arel_Attributes_Attribute
          alias :visit_Arel_Attributes_Decimal :visit_Arel_Attributes_Attribute
          alias :visit_Arel_Attributes_String :visit_Arel_Attributes_Attribute
          alias :visit_Arel_Attributes_Time :visit_Arel_Attributes_Attribute
          alias :visit_Arel_Attributes_Boolean :visit_Arel_Attributes_Attribute

          def visit_Fixnum o; o end
          alias :visit_Arel_Nodes_SqlLiteral :visit_Fixnum
          alias :visit_Arel_SqlLiteral :visit_Fixnum # This is deprecated
          alias :visit_Bignum :visit_Fixnum

          def visit_String o
           quote(o, last_column)
           #o.inspect if o.present?
          end

          #def visit_DateTime o
          #  o.to_s.inspect
          #end

          def last_column
            Thread.current[:arel_visitors_to_sql_last_column]
          end

          def last_column= col
            Thread.current[:arel_visitors_to_sql_last_column] = col
          end

          alias :visit_ActiveSupport_Multibyte_Chars :visit_String
          alias :visit_BigDecimal :visit_String
          alias :visit_Date :visit_String
          #alias :visit_Date :visit_DateTime
          alias :visit_DateTime :visit_String
          alias :visit_FalseClass :visit_String
          alias :visit_Float :visit_String
          alias :visit_Hash :visit_String
          alias :visit_Symbol :visit_String
          alias :visit_Time :visit_String
          #alias :visit_Time :visit_DateTime
          alias :visit_TrueClass :visit_String
          alias :visit_NilClass :visit_String
          alias :visit_ActiveSupport_StringInquirer :visit_String
          alias :visit_Class :visit_String

          def visit_Array o
            #o.empty? ? 'NULL' : o.map { |x| visit x }.join(', ')
            o.empty? ? nil : o.map { |x| visit x }.inspect
          end

          def quote value, column = nil
            @connection.quote value, column
          end

          def quote_table_name name
            @quoted_tables[name] ||= @connection.quote_table_name(name)
          end

          def quote_column_name name
            @quoted_columns[name] ||= @connection.quote_column_name(name)
          end
        end # Neo4jVisitor
      end # Sql
    end # Neo4j
  end # Visitors
end # Arel