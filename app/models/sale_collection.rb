class SaleCollection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sale_id, type: Integer
  field :collections, type: Hash

  belongs_to :sale
end
