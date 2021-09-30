# frozen_string_literal: true

require "rom/elasticsearch/query_multiplexer"

RSpec.describe ROM::Elasticsearch::QueryMultiplexer, "#call" do
  subject(:multiplexer) do
    ROM::Elasticsearch::QueryMultiplexer.new(client)
  end

  let(:relation) { relations[:users] }

  include_context "users"

  before do
    relation.command(:create).(id: 1, name: "Eve")
    relation.command(:create).(id: 2, name: "Bob")
    relation.command(:create).(id: 3, name: "Alice")

    relation.refresh
  end

  it "returns an array of response" do
    resp = multiplexer.relations([
                                   relation.query(match: { name: "Bob" }),
                                   relation.query(match: { name: "Eve" })
                                 ]).call

    expect(resp[0].to_a).to match_array([{ id: 2, name: "Bob" }])
    expect(resp[1].to_a).to match_array([{ id: 1, name: "Eve" }])
  end
end