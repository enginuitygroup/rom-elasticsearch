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

        Bucket = Types::Hash.schema(
          key:       Types::String,
          doc_count: Types::Integer,
          children:  Types::Array.of(Types::Instance(self))
        ).with_key_transform(&:to_sym)

        def buckets
          return [] unless aggregation_response.has_key?('buckets')
          aggregation_response['buckets'].map do |bucket|
            bucket[:children] = resolver.call(aggregation.children, bucket)
            Bucket[bucket]
          end
        end        

        def method_missing(name)
          raise NameError, "#{name} is not a valid attribute" unless aggregation_response.has_key?(name.to_s)
          aggregation_response[name.to_s]
        end
      end
    end
  end
end