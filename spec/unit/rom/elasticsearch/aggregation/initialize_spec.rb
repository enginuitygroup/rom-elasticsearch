# frozen_string_literal: true

require "rom/elasticsearch/aggregation"

RSpec.describe ROM::Elasticsearch::Aggregation, ".new" do
  it "returns an instance with the correct name" do
    agg = described_class.new(:sum)
    expect(agg.name).to eql(:sum)
  end

  it "returns itself if passed an instance" do
    first_agg = described_class.new(:sum)
    second_agg = described_class.new(first_agg)
    expect(second_agg).to eql(first_agg)
  end
end
