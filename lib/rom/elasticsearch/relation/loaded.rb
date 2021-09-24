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
          if response.fetch("responses").count > 1
            response.fetch("responses").map do |res|
              res.fetch("hits").fetch("total").fetch("value")
            end
          else
            response.fetch("responses").first.fetch("hits").fetch("total").fetch("value")
          end
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
          Aggregation::ResponseResolver.call(
            source.dataset.options[:aggregations],
            response["responses"].size > 1 ? response["responses"].map{ |response|
              response["aggregations"]
            } : response["responses"].first["aggregations"]
          )
        end
      end
    end
  end
end
