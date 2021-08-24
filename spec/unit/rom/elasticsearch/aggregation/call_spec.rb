# frozen_string_literal: true

require "rom/elasticsearch/aggregation"

RSpec.describe ROM::Elasticsearch::Aggregation, "#call" do
  subject(:aggregation) { described_class[:sum] }

  it "returns itself" do
    result = aggregation.call("name")
    expect(result).to eql(aggregation)
  end

  it "sets the field name" do
    result = aggregation.call("name")
    expect(result.field).to eql("name")
  end

  it "sets a default alias" do
    result = aggregation.call("name")
    expect(result.alias).to eql("sum_name")
  end

  it "sets a specified alias" do
    result = aggregation.call("name", alias: "custom_alias")
    expect(result.alias).to eql("custom_alias")
  end

  it "doesn't include the alias in the parameters" do
    result = aggregation.call("name", alias: "custom_alias")
    expect(result.paramters).not_to include(alias: "custom_alias")
  end
  
  it "sets the specified parameters" do
    result = aggregation.call("name", foo: "bar", baz: 5)
    expect(result.parameters).to include(foo: "bar", baz: 5)
  end
end