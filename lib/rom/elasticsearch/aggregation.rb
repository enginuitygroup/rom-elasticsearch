# frozen_string_literal: true

module ROM
  module Elasticsearch
    class Aggregation
      attr_reader :name, :field, :parameters

      def self.[](name)
        if name.is_a?(self)
          name
        else
          new(name)
        end
      end

      def initialize(name)
        @name       = name
        @field      = nil
        @parameters = {}
        @children   = []
      end

      def call(field, **kwargs)
        @field      = field
        @parameters = kwargs
        self
      end

      def <<(aggregation)
        @children << aggregation if aggregation.is_a?(self.class)
      end 
    end
  end
end