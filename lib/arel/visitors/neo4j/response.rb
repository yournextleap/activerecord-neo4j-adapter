module Arel
  module Visitors
    module Neo4j
      class Response
        attr_reader :type, :params
        def initialize(type, options)
          @type = type
          @params = options[:params] if options[:params].present?
        end

        def gsub(match, replacement)
          params_array = Array.wrap @params
          params_array.map{|params| params[:query].gsub(match, replacement)}.join
        end # gsub
      end # Response
    end # Neo4j
  end # Visitors
end # Arel