class Shop < ActiveRecord::Base
	has_many :sale, :dependent => :destroy

  include ShopifyApp::SessionStorage

  def with_shopify!
		session = ShopifyAPI::Session.new(shopify_domain, shopify_token)
		ShopifyAPI::Base.activate_session(session)
	end

	def nullify_cap
		self.with_shopify!

		pc = ShopifyAPI::Product.count
		count = 0
		page = 1
		while count < pc
			products = ShopifyAPI::Product.find(:all, params: {limit: '250', fields: 'id,variants', page: page})
			products.each do |product|
				if ShopifyAPI.credit_left < 5
					sleep 10.seconds
				end
				check = false
				product.variants.each do |variant|
					if !variant.compare_at_price.nil?
						check = true
						variant.compare_at_price = nil
					end
				end
				if check
					product.save
				end
			end
			page +=1
			count += 250
			puts count
		end

	end
end
