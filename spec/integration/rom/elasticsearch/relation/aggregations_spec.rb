# frozen_string_literal: true

RSpec.describe ROM::Elasticsearch::Relation, ".aggregations" do
  subject(:relation) { relations[:purchases] }

  include_context "setup"

  before do
    conf.relation(:purchases) do
      schema(:purchases) do
        attribute :purchase_type, ROM::Elasticsearch::Types.Keyword
        attribute :purchase_price, ROM::Elasticsearch::Types::Integer
      end
    end

    relations[:purchases].create_index

    relations[:purchases].command(:create).call(
      purchase_type: "credit",
      purchase_price: 100
    )
    relations[:purchases].command(:create).call(
      purchase_type: "credit",
      purchase_price: 200
    )
    relations[:purchases].command(:create).call(
      purchase_type: "cash",
      purchase_price: 50
    )
    relations[:purchases].command(:create).call(
      purchase_type: "cash",
      purchase_price: 100
    )
    relations[:purchases].command(:create).call(
      purchase_type: "cash",
      purchase_price: 50
    )

    relations[:purchases].refresh
  end

  after do
    relations[:purchases].delete_index
  end

  describe "sum metrics aggregation" do
    let(:aggregation) { ROM::Elasticsearch::Aggregation.new(:sum).call(:purchase_price) }

    it "returns aggregations" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations.count).to eq 1
    end

    it "returns an aggregation with the correct value" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations["sum_purchase_price"].value).to eq 500
    end

    it "returns an aggregation with an empty buckets list" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations["sum_purchase_price"].buckets).to eq []
    end

    it "returns aggregations with a search query" do
      result = relation
        .query(match: { purchase_type: "credit"})
        .aggregations(aggregation)
        .call

      expect(result.aggregations.count).to eq 1
      expect(result.aggregations["sum_purchase_price"].value).to eq 300
    end
  end

  describe "avg metrics aggregation" do
    let(:aggregation) { ROM::Elasticsearch::Aggregation.new(:avg).call(:purchase_price) }

    it "returns aggregations" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations.count).to eq 1
    end

    it "returns an aggregation with the correct value" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations["avg_purchase_price"].value).to eq 100
    end

    it "returns an aggregation with an empty buckets list" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations["avg_purchase_price"].buckets).to eq []
    end

    it "returns aggregations with a search query" do
      result = relation
        .query(match: { purchase_type: "credit"})
        .aggregations(aggregation)
        .call

      expect(result.aggregations.count).to eq 1
      expect(result.aggregations["avg_purchase_price"].value).to eq 150
    end
  end
  
  describe "bucket aggregation" do
    let(:aggregation) { ROM::Elasticsearch::Aggregation.new(:terms).call(:purchase_type) }

    it "returns aggregations and buckets" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations.count).to eq 1
      expect(result.aggregations["terms_purchase_type"].buckets.count).to eq 2
    end

    it "returns an aggregation with the correct buckets" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations["terms_purchase_type"].buckets).to include a_hash_including(key: "credit", doc_count: 2)
      expect(result.aggregations["terms_purchase_type"].buckets).to include a_hash_including(key: "cash", doc_count: 3)
    end

    it "applies the aggregation to a search query" do
      result = relation
        .query(bool: {
          must: { match_all: {} },
          filter: { range: { purchase_price: { gte: 100 } } }
        })
        .aggregations(aggregation)
        .call

      expect(result.aggregations.count).to eq 1
      expect(result.aggregations["terms_purchase_type"].buckets.count).to eq 2
      expect(result.aggregations["terms_purchase_type"].buckets).to include a_hash_including(key: "credit", doc_count: 2)
      expect(result.aggregations["terms_purchase_type"].buckets).to include a_hash_including(key: "cash", doc_count: 1)
    end
  end

  describe "a metrics aggregation under a bucket aggregation" do
    let(:aggregation) do
      ROM::Elasticsearch::Aggregation.new(:terms).tap do |terms|
        terms << ROM::Elasticsearch::Aggregation.new(:sum).call(:purchase_price)
      end.call(:purchase_type)
    end

    it "returns aggregations and buckets" do
      result = relation.aggregations(aggregation).call
      expect(result.aggregations.count).to eq 1
      expect(result.aggregations["terms_purchase_price"].buckets.count).to eq 2
      expect(result.aggregations["terms_purchase_price"].buckets.first[:children].count).to eq 1
      expect(result.aggregations["terms_purchase_price"].buckets[1][:children].count).to eq 1
    end

    it "returns an aggregation with the correct buckets" do
      result = relation.aggregations(aggregation).call
      # byebug
      expect(result.aggregations["terms_purchase_price"].buckets).to include a_hash_including(
        key: "credit", 
        doc_count: 2,
        children: including(
          satisfying("has correct value") {|o| o.value == 300.0 }
        )
      )

      expect(result.aggregations["terms_purchase_price"].buckets).to include a_hash_including(
        key: "cash", 
        doc_count: 3,
        children: including(
          satisfying("has correct value") {|o| o.value == 200.0 }
        )
      )
    end
  end
  it "applies a bucket aggregation"
  it "applies a bucket aggregation to a search query"

  it "applies a metrics aggregation under a bucket aggregation"

end