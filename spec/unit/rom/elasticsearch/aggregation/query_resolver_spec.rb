# frozen_string_literal: true

require "rom/elasticsearch/aggregation"
require "rom/elasticsearch/aggregation/query_resolver"

RSpec.describe ROM::Elasticsearch::Aggregation::QueryResolver do
  subject(:fragment) { described_class.new(aggregations).to_query_fragment }

  describe "with a single aggregation" do
    let(:aggregations) do
      [ROM::Elasticsearch::Aggregation[:sum].call("price")]
    end

    it "returns a hash with the correct body" do
      expect(fragment).to eql({
        "sum_price": { "sum": { "field": "price" } }
      })
    end
  end

  describe "with two aggregations" do
    let(:aggregations) do
      [
        ROM::Elasticsearch::Aggregation[:sum].call("price"),
        ROM::Elasticsearch::Aggregation[:avg].call("price")
      ]
    end

    it "returns a hash with the correct body" do
      expect(fragment).to eql({
        "sum_price": { "sum": { "field": "price" } },
        "avg_price": { "avg": { "field": "price" } }
      })
    end
  end

  describe "with a nested aggregation" do
    let(:parent_aggregation) do
      ROM::Elasticsearch::Aggregation[:range].tap do |agg|
        agg << child_aggregation
      end.call("price")
    end

    let(:child_aggregation) { ROM::Elasticsearch::Aggregation[:sum].call("price") }
    let(:aggregations) { [parent_aggregation] }

    it "returns a hash with the correct body" do
      expect(fragment).to eql({
        "range_price": {
          "range": { "field": "price" },
          "aggs": {
            "sum_price": {
              "sum": { "field": "price" }
            }
          }
        }
      })
    end
  end
end