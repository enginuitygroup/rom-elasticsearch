# frozen_string_literal: true

require "rom/elasticsearch/aggregation/loaded"

module ROM
  module Elasticsearch
    class Aggregation
      class ResponseResolver
        def self.call(aggregations, response)
          aggregations.map do |aggregation|
            Loaded.new(
              aggregation,
              response[aggregation.label],
              self
            )
          end
        end
      end
    end
  end
end