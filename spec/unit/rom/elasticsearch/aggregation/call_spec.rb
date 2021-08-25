# frozen_string_literal: true

require "rom/elasticsearch/aggregation"

RSpec.describe ROM::Elasticsearch::Aggregation, "#call" do
  subject(:aggregation) { described_class.new(:sum) }

  it "returns itself" do
    result = aggregation.call("name")
    expect(result).to eql(aggregation)
  end

  it "sets the field name" do
    result = aggregation.call("name")
    expect(result.field).to eql("name")
  end

  it "sets a default label" do
    result = aggregation.call("name")
    expect(result.label).to eql("sum_name")
  end

  it "sets a specified label" do
    result = aggregation.call("name", label: "custom_label")
    expect(result.label).to eql("custom_label")
  end

  it "doesn't include the label in the parameters" do
    result = aggregation.call("name", label: "custom_label")
    expect(result.parameters).not_to include(label: "custom_label")
  end
  
  it "sets the specified parameters" do
    result = aggregation.call("name", foo: "bar", baz: 5)
    expect(result.parameters).to include(foo: "bar", baz: 5)
  end
end