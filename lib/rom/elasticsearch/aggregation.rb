# frozen_string_literal: true

module ROM
  module Elasticsearch
    class Aggregation
      attr_reader :label, :name, :field, :parameters, :children

      def initialize(name)
        @name       = name
        @label      = nil
        @field      = nil
        @parameters = {}
        @children   = []
      end

      def call(field, label: nil, **kwargs)
        @field      = field
        @parameters = kwargs
        @label      = label || "#{name}_#{field}"
        self
      end

      def <<(aggregation)
        @children << aggregation if aggregation.is_a?(self.class)
      end 
    end
  end
end