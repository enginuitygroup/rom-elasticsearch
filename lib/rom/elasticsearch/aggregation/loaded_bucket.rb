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
          unless bucket_payload.key?(name.to_s)
            raise NameError,
                  "#{name} is not a valid attribute"
          end

          bucket_payload[name.to_s]
        end
      end
    end
  end
end
