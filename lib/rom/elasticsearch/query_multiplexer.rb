# frozen_string_literal: true

require "rom/initializer"

module ROM
  module Elasticsearch
    class QueryMultiplexer
      extend Initializer

      param :client
      option :relations, default: -> { [] }
      option :response, optional: true, reader: false

      def relations(new = nil)
        if new.nil?
          @relations
        else
          new = [new] unless new.is_a?(Array)
          with(relations: relations.concat(new))
        end
      end

      def body
        relations.map {|r| [r.dataset.params, r.dataset.body] }.flatten
      end

      # def to_a
      #   to_enum.to_a
      # end
      #
      # def each
      #   return to_enum unless block_given?
      #
      #   relations.each.with_index do |relation, index|
      #     relation_response = response["responses"][index]
      #     yield relation.with(dataset: dataset.with(response: relation_response)).call
      #   end
      # end
      #
      # def map(&block)
      #   to_a.map(&block)
      # end

      def call
        relations.map.with_index do |relation, index|
          relation_response = response["responses"][index]
          relation.with(
            dataset: relation.dataset.with(response: relation_response)
          ).call
        end
      end

      private
      def response
        options[:response] || client.msearch(body: body)
      end
    end
  end
end