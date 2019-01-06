Shop.first.with_shopify!

vs = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price"})

page = 1

errors = []

while !vs.empty?
	vs.each do |v|

		if OldPrice.find_by(variant_id: v.id).nil?
			errors += [v.id]
		end
	end

	page += 1
	vs = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price", page: page})
end

# OldPrice.count = 1149