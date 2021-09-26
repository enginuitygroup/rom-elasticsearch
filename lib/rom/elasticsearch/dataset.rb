# frozen_string_literal: true

require "rom/initializer"

require "rom/elasticsearch/query_methods"
require "rom/elasticsearch/scroll_methods"
require "rom/elasticsearch/aggregation/query_resolver"
require "rom/elasticsearch/errors"

module ROM
  module Elasticsearch
    # Elasticsearch dataset
    #
    # Uses an elasticsearch client object provided by the gateway, holds basic
    # params with information about index name and type, and optional body for
    # additional queries.
    #
    # Dataset object also provide meta information about indices, like custom
    # settings and mappings.
    #
    # @api public
    class Dataset
      extend Initializer

      include QueryMethods
      include ScrollMethods

      # Sort values separator
      SORT_VALUES_SEPARATOR = ","

      # Default query options
      ALL = {query: {match_all: EMPTY_HASH}}.freeze

      # The id key in raw results
      ID_KEY = "_id"

      # The source key in raw results
      SOURCE_KEY = "_source"

      # @!attribute [r] client
      #   @return [::Elasticsearch::Client] configured client from the gateway
      param :client

      # @!attribute [r] params
      #   @return [Hash] default params
      option :params, default: -> { EMPTY_HASH }

      # @!attribute [r] client
      #   @return [Hash] default body
      option :body, default: -> { EMPTY_HASH }

      # @!attribute [r] include_metadata
      #   @return [Bool]
      option :include_metadata, default: -> { false }

      # @!attribute [r] response
      #   @return [Hash] memoized response from the client
      option :response, optional: true, reader: false

      # @!attribute [r] aggregations
      #   @return [Array<Aggregation>] an array of aggregation objects
      option :aggregations, default: -> { [] }

      # @!attribute [r] tuple_proc
      #   @return [Proc] low-level tuple processing function used in #each
      attr_reader :tuple_proc

      # default tuple proc which extracts raw source data from response item
      TUPLE_PROC = -> t { t[SOURCE_KEY] }

      # tuple proc used when :include_metadata is enabled, resulting tuples
      # will include raw response hash under _metadata key
      TUPLE_PROC_WITH_METADATA = -> t { TUPLE_PROC[t].merge(_metadata: t) }

      option :tuple_proc, default: -> {
                                     options[:include_metadata] ? TUPLE_PROC_WITH_METADATA : TUPLE_PROC
                                   }

      # # @api private
      # def initialize(*args, **kwargs)
      #   super
      # end

      # Put new data under configured index
      #
      # @param [Hash] data
      #
      # @return [Hash]
      #
      # @api public
      def put(data)
        client.index(**params, body: data)
      end

      # Return index settings
      #
      # @return [Hash]
      #
      # @api public
      def settings
        client.indices.get_settings[index.to_s]["settings"]["index"]
      end

      # Return index mappings
      #
      # @return [Hash]
      #
      # @api public
      def mappings
        client.indices.get_mapping[index.to_s]["mappings"]
      end

      # Delete everything matching configured params and/or body
      #
      # If body is empty it *will delete everything**
      #
      # @return [Hash] raw response hash from the client
      #
      # @api public
      def delete
        if body.empty? && params[:id]
          client.delete(params)
        elsif body.empty?
          client.delete_by_query(params.merge(body: body.merge(ALL)))
        else
          client.delete_by_query(params.merge(body: body))
        end
      end

      # Materialize the dataset
      #
      # @return [Array<Hash>]
      #
      # @api public
      def to_a
        to_enum.to_a
      end

      # Materialize and iterate over results
      #
      # @yieldparam [Hash]
      #
      # @raise [SearchError] in case of the client raising an exception
      #
      # @api public
      def each
        return to_enum unless block_given?

        view.each { |result| yield(tuple_proc[result]) }
      rescue ::Elasticsearch::Transport::Transport::Error => e
        raise SearchError.new(e, options)
      end

      # Map dataset tuples
      #
      # @yieldparam [Hash]
      #
      # @return [Array]
      #
      # @api public
      def map(&block)
        to_a.map(&block)
      end

      # Return configured type from params
      #
      # @return [Symbol]
      #
      # @api public
      def type
        params[:type]
      end

      # Return configured index name
      #
      # @return [Symbol]
      #
      # @api public
      def index
        params[:index]
      end

      # Return a new dataset with new body
      #
      # @param [Hash] new New body data
      #
      # @return [Hash]
      #
      # @api public
      def body(new = nil)
        if new.nil?
          @body
        else
          constructed_body = []
          new.each { |query| constructed_body.push(query) }
          with(body: constructed_body)
        end
      end

      # Return a new dataset with new aggregations
      #
      # @param [Array<Aggregation>] new New aggregations
      #
      # @return [Hash]
      #
      # @api public
      def aggregations(new = nil)
        if new.nil?
          @aggregations
        else
          new = [new] unless new.is_a?(Enumerable)
          with(aggregations: aggregations.concat(new))
        end
      end

      # Return a new dataset with new params
      #
      # @param [Hash] new New params data
      #
      # @return [Hash]
      #
      # @api public
      def params(new = nil)
        if new.nil?
          @params
        else
          with(params: params.merge(new))
        end
      end

      # Refresh index
      #
      # @return [Dataset]
      #
      # @api public
      def refresh
        client.indices.refresh(index: index)
        self
      end

      # Return dataset with :sort set
      #
      # @return [Dataset]
      #
      # @api public
      def sort(*fields)
        params(sort: fields.join(SORT_VALUES_SEPARATOR))
      end

      # Return dataset with :from set
      #
      # @param [Integer] num
      #
      # @return [Dataset]
      #
      # @api public
      def from(num)
        params(from: num)
      end

      # Return dataset with :size set
      #
      # @param [Integer] num
      #
      # @return [Dataset]
      #
      # @api public
      def size(num)
        params(size: num)
      end

      # Create an index
      #
      # @param [Hash] opts ES options
      #
      # @api public
      #
      # @return [Hash]
      def create_index(opts = EMPTY_HASH)
        client.indices.create(params.merge(opts))
      end

      # Delete an index
      #
      # @param [Hash] opts ES options
      #
      # @api public
      #
      # @return [Hash]
      def delete_index(opts = EMPTY_HASH)
        client.indices.delete(params.merge(opts))
      end

      # Return a dataset with pre-set client response
      #
      # @return [Dataset]
      #
      # @api public
      def call
        with(response: response)
      end

      def call_with_response(res)
        with(response: res)
      end

      def accessible_response
        response
      end

      private

      # Return results of a query based on configured params and body
      #
      # @return [Array<Hash>]
      #
      # @api private
      def view
        if params[:id]
          [client.get(params)]
        elsif params[:scroll]
          scroll_enumerator(client, response)
        else
          response.fetch("hits").fetch("hits")
        end
      end

      # @api private
      def response
        if options[:response]
          options[:response]
        else
          res = client.msearch(**params, body: body_with_aggregations)
          body.size == 1 ? res["responses"].first : res
        end
      end

      def body_with_aggregations
        constructed_body = []
        if aggregations.empty?
          return [{search: body}] if body.is_a?(Hash)

          body.each do |query|
            constructed_body.push({search: query})
          end
        else
          if body.is_a?(Hash)
            return [{search: define_aggregations(body)}]
          end

          body.each { |query|
            constructed_body.push({search: define_aggregations(query)})
          }
        end
        constructed_body
      end

      def define_aggregations(obj)
        obj.merge(aggs: body.fetch(:aggs, {})
                            .merge(Aggregation::QueryResolver.new(aggregations)
                                       .to_query_fragment))
      end
    end
  end
end
