# frozen_string_literal: true

require "rom/elasticsearch/aggregation/response_resolver"

module ROM
  module Elasticsearch
    class Relation < ROM::Relation
      # Materialized index data
      #
      # @api public
      class Loaded < ROM::Relation::Loaded
        # Return total number of hits
        #
        # @return [Integer]
        #
        # @api public
        def total_hits
          response['hits']['total']['value']
        end

        # Return raw response from the ES client
        #
        # @return [Hash]
        #
        # @api public
        def response
          source.dataset.options[:response]
        end

        # Return array of LoadedAggregation objects
        #
        # @return [LoadedAggregation]
        #
        # @api public
        def aggregations
          byebug if response['aggregations'].nil?
          Aggregation::ResponseResolver.call(
            source.dataset.options[:aggregations],
            response['aggregations']
          )
        end
      end
    end
  end
end
