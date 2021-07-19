class OldPrice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sale_id, type: Integer
  field :product_id, type: Integer
  field :variants, type: Hash

  belongs_to :sale
end
