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
          aggregation_response.has_key?('buckets')
        end

        def buckets
          return [] unless has_buckets?
          aggregation_response['buckets'].map do |bucket|
            LoadedBucket.new(aggregation, bucket, resolver)
          end
        end        

        def label
          aggregation.label
        end

        def method_missing(name)
          raise NameError, "#{name} is not a valid attribute" unless aggregation_response.has_key?(name.to_s)
          aggregation_response[name.to_s]
        end
      end
    end
  end
end