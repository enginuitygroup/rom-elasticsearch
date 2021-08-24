# frozen_string_literal: true

require "rom/elasticsearch/aggregation"

RSpec.describe ROM::Elasticsearch::Aggregation, ".[]" do
  it "returns an instance of itself" do
    agg = described_class[:sum]
    expect(agg).to be_an_instance_of(described_class)
  end

  it "returns an instance with the correct name" do
    agg = described_class[:sum]
    expect(agg.name).to eql(:sum)
  end

  it "returns itself if passed an instance" do
    first_agg = described_class[:sum]
    second_agg = described_class[first_agg]
    expect(second_agg).to eql(first_agg)
  end
end