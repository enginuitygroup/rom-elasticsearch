# frozen_string_literal: true

require "rom/elasticsearch/aggregation"

RSpec.describe ROM::Elasticsearch::Aggregation, "#<<" do
  subject(:aggregation) { described_class.new(:sum) }

  it "adds children" do
    child_aggregation = described_class.new(:avg)
    aggregation << child_aggregation
    expect(aggregation.children).to include child_aggregation
  end

  it "skips adding non-Aggregation children" do
    aggregation << :avg
    expect(aggregation.children.count).to eql 0
  end
end