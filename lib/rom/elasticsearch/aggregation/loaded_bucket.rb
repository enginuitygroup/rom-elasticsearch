# frozen_string_literal: true

require "rom/initializer"

module ROM
  module Elasticsearch
    class Aggregation
      class LoadedBucket
        extend Initializer

        param :aggregation
        param :bucket_payload
        param :resolver

        def aggregations
          resolver.call(aggregation.children, bucket_payload)
        end

        def key
          bucket_payload["key"]
        end

        def doc_count
          bucket_payload["doc_count"]
        end

        def method_missing(name)
          raise NameError, "#{name} is not a valid attribute" unless bucket_payload.has_key?(name.to_s)
          bucket_payload[name.to_s]
        end
      end
    end
  end
end