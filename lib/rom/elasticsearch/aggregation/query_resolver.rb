# frozen_string_literal: true

require "rom/initializer"

module ROM
  module Elasticsearch
    class Aggregation
      class QueryResolver
        extend Initializer
        
        param :aggregations, default: -> { [] }

        def empty?
          @aggregations.empty?
        end
        
        def to_query_fragment
          @aggregations.reduce({}) do |fragment, aggregation|
            fragment.merge(hash_for(aggregation))
          end
        end

        private def hash_for(aggregation)
          body = aggregation.parameters.merge({ field: aggregation.field.to_s })
          sub_aggs = {}

          if !aggregation.children.empty?
            sub_aggs[:aggs] = QueryResolver.new(aggregation.children).to_query_fragment
          end

          {
            aggregation.label => {
              aggregation.name => body
            }.merge(sub_aggs)
          }
        end
      end
    end
  end
end