# frozen_string_literal: true

require "rom/initializer"
require "rom/types"

module ROM
  module Elasticsearch
    class Aggregation
      class Loaded
        extend Initializer

        param :aggregation
        param :aggregation_response
        param :resolver

        def has_buckets?
          aggregation_response.key?("buckets")
        end

        def buckets
          return [] unless has_buckets?

          aggregation_response["buckets"].map do |bucket|
            ROM::Elasticsearch::Aggregation::LoadedBucket.new(aggregation, bucket, resolver)
          end
        end

        def label
          aggregation.label
        end

        def method_missing(name)
          unless aggregation_response.key?(name.to_s)
            raise NameError,
                  "#{name} is not a valid attribute"
          end

          aggregation_response[name.to_s]
        end
      end
    end
  end
end
