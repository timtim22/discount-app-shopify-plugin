file = File. open("variant_prices.txt", "w")
Shop.first.with_shopify!
count = ShopifyAPI::Product.count
page = 1
c = 1
while count > 0
	products = ShopifyAPI::Product.find(:all, :params => {:limit => 250, :page => page})
	products.each do |product|
		product.variants.each do |variant|
			file << c.to_s+". "+variant.id.to_s+" : "+variant.price+"\n"
			c += 1
		end
	end
	count -= 250
	page += 1
end
file.close