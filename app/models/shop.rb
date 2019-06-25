class Shop < ApplicationRecord
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

	def transfer(target_shop_id, price_multiplier=nil)
		target_shop = Shop.find(target_shop_id)
		attributes_to_remove =  %w(admin_graphql_api_id created_at updated_at id published_at)
		product_map = {}
		custom_collection_map = {}


		self.with_shopify_session do

			page = 1
			count = 1

			puts 'copy smart collections'

			all_smart_collections = self.safe_request { ShopifyAPI::SmartCollection.find(:all, params: {limit: '250', page: page}) }
			while !all_smart_collections.empty?
				if ShopifyAPI.credit_left < 10
			    sleep 10.seconds
			  end
				page += 1
				target_shop.with_shopify_session do
					all_smart_collections.each do |smart_collection|
					  hashed_smart_collection = JSON.parse smart_collection.to_json
					  attributes_to_remove.each {|attribute| hashed_smart_collection.delete attribute }
					  self.safe_request { ShopifyAPI::SmartCollection.create hashed_smart_collection }
					  puts "Smart collection # #{count} copied, API limit left: #{ShopifyAPI.credit_left}"
					  count += 1
					  if ShopifyAPI.credit_left < 10
					    sleep 10.seconds
					  end
					end
				end
				all_smart_collections = self.safe_request { ShopifyAPI::SmartCollection.find(:all, params: {limit: '250', page: page}) }
			end

			puts 'copy custom collections'

			page = 1
			custom_collection_product_ids = []
			all_custom_collections = self.safe_request { ShopifyAPI::CustomCollection.find(:all, params: {limit: '250', page: page}) }
			while !all_custom_collections.empty?
				page += 1
				all_custom_collections.each do |custom_collection|
				  hashed_custom_collection = JSON.parse custom_collection.to_json
				  attributes_to_remove.each {|attribute| hashed_custom_collection.delete attribute }
				  target_shop.with_shopify_session do
					  new_custom_collection = self.safe_request { ShopifyAPI::CustomCollection.create hashed_custom_collection }
					  puts "Custom collection # #{custom_collection.id} copied, API limit left: #{ShopifyAPI.credit_left}"
					  custom_collection_map[custom_collection.id] = new_custom_collection.id

				    sleep 10.seconds if ShopifyAPI.credit_left < 10
					end
				end
				all_custom_collections = self.safe_request { ShopifyAPI::CustomCollection.find(:all, params: {limit: '250', page: page}) }
		    sleep 10.seconds if ShopifyAPI.credit_left < 10
			end

			puts 'coping products'

			page = 1
			products = self.safe_request { ShopifyAPI::Product.find(:all, params: {limit: '250', page: page}) }
			while !products.empty?
				products.each do |product|
				  hashed_product = JSON.parse product.to_json
				  attributes_to_remove.each {|attribute| hashed_product.delete attribute }
				  hashed_product['variants'].each do |v|
				  	v.delete 'image_id'
				  	if price_multiplier
							v['price'] = (v['price'].to_i * price_multiplier).round if v['price'] && v['price'].to_i > 0
							v['compare_at_price'] = (v['compare_at_price'].to_i * price_multiplier).round if v['compare_at_price'] && v['compare_at_price'].to_i > 0
						end
				  end
					target_shop.with_shopify_session do
					  new_product = self.safe_request { ShopifyAPI::Product.create hashed_product }
					  puts "Product # #{count} copied, API limit left: #{ShopifyAPI.credit_left}"
					  product_map[product.id] = new_product.id
				    sleep 10.seconds if ShopifyAPI.credit_left < 10
					end
				end
				products = self.safe_request { ShopifyAPI::Product.find(:all, params: {limit: '250', page: page}) }
		    sleep 10.seconds if ShopifyAPI.credit_left < 10
			end

			puts 'copy product to custom_collection relation i-e collect'

			page = 1
			count = 1
			all_collects = self.safe_request { ShopifyAPI::Collect.find(:all, params: {limit: '250', page: page}) }
			while !all_collects.empty?
				page += 1

				all_collects.each do |collect|
				  hashed_collect = JSON.parse collect.to_json
				  attributes_to_remove.each {|attribute| hashed_collect.delete attribute }
				  target_shop.with_shopify_session do
					  self.safe_request { ShopifyAPI::Collect.create({product_id: product_map[collect.product_id], collection_id: custom_collection_map[collect.collection_id]}) }
					  puts "Collect # #{count} created, API limit left: #{ShopifyAPI.credit_left}"
					  count += 1
					  sleep 10.seconds if ShopifyAPI.credit_left < 10
					end
				end
				all_collects = self.safe_request { ShopifyAPI::Collect.find(:all, params: {limit: '250', page: page}) }
				sleep 10.seconds if ShopifyAPI.credit_left < 10
			end
		end
	end

	def transfer_old(target_shop_id, price_multiplier=nil)
		target_shop = Shop.find(target_shop_id)
		attributes_to_remove =  %w(admin_graphql_api_id created_at updated_at id published_at)


		page = 1
		count = 1
		self.with_shopify_session do

			#copy smart collections
			all_smart_collections = self.safe_request { ShopifyAPI::SmartCollection.find(:all, params: {limit: '250', page: page}) }
			while !all_smart_collections.empty?
				if ShopifyAPI.credit_left < 10
			    sleep 10.seconds
			  end
				page += 1
				target_shop.with_shopify_session do
					all_smart_collections.each do |smart_collection|
					  hashed_smart_collection = JSON.parse smart_collection.to_json
					  attributes_to_remove.each {|attribute| hashed_smart_collection.delete attribute }
					  self.safe_request { ShopifyAPI::SmartCollection.create hashed_smart_collection }
					  puts "Smart collection # #{count} copied, API limit left: #{ShopifyAPI.credit_left}"
					  count += 1
					  if ShopifyAPI.credit_left < 10
					    sleep 10.seconds
					  end
					end
				end
				all_smart_collections = self.safe_request { ShopifyAPI::SmartCollection.find(:all, params: {limit: '250', page: page}) }
			end

			#copy custom collections
			page = 1
			count = 1
			custom_collection_product_ids = []
			all_custom_collections = self.safe_request { ShopifyAPI::CustomCollection.find(:all, params: {limit: '250', page: page}) }
			while !all_custom_collections.empty?
				if ShopifyAPI.credit_left < 10
			    sleep 10.seconds
			  end
				page += 1
				target_shop.with_shopify_session do
					all_custom_collections.each do |custom_collection|

					  hashed_custom_collection = JSON.parse custom_collection.to_json
					  attributes_to_remove.each {|attribute| hashed_custom_collection.delete attribute }
					  new_custom_collection = self.safe_request { ShopifyAPI::CustomCollection.create hashed_custom_collection }
					  puts "Custom collection # #{custom_collection.id} copied, API limit left: #{ShopifyAPI.credit_left}"
					  count += 1
					  if ShopifyAPI.credit_left < 10
					    sleep 10.seconds
					  end
					  self.with_shopify_session do
						  c_page = 1
						  c_count = 1
						  products = self.safe_request { ShopifyAPI::Product.find(:all, params: {limit: '250', page: c_page, collection_id: custom_collection}) }
						  while !products.empty?
						  	if ShopifyAPI.credit_left < 10
							    sleep 10.seconds
							  end
						  	c_page += 1
						  	products.each do |product|
						  		if custom_collection_product_ids.include?(product.id)
						  			target_shop.with_shopify_session do
						  				present_product = self.safe_request { ShopifyAPI::Product.find(:first, params: {title: product.title}) }
						  				self.safe_request { ShopifyAPI::Collect.create({product_id: present_product.id, collection_id: new_custom_collection.id}) }
						  				puts "Product #{product.id} added to collection, API limit left: #{ShopifyAPI.credit_left}"
						  				if ShopifyAPI.credit_left < 10
										    sleep 10.seconds
										  end
						  			end
						  		else
									  hashed_product = JSON.parse product.to_json
									  attributes_to_remove.each {|attribute| hashed_product.delete attribute }
									  hashed_product['variants'].each do |v|
									  	v.delete 'image_id'
									  	if price_multiplier
												v['price'] = v['price'].to_i * price_multiplier if v['price'] && v['price'].to_i > 0
												v['compare_at_price'] = v['compare_at_price'] * price_multiplier if v['compare_at_price'] && v['compare_at_price'].to_i > 0
											end
									  end
									  target_shop.with_shopify_session do
										  new_product = self.safe_request { ShopifyAPI::Product.create hashed_product }
										  puts "Product #{product.id} copied, API limit left: #{ShopifyAPI.credit_left}"
										  self.safe_request { ShopifyAPI::Collect.create({product_id: new_product.id, collection_id: new_custom_collection.id}) }
										  custom_collection_product_ids << product.id
										  puts "Product #{product.id} added to collection, API limit left: #{ShopifyAPI.credit_left}"
					  					c_count += 1
					  					if ShopifyAPI.credit_left < 10
										    sleep 10.seconds
										  end
										end
									end
						  	end
						  	products = self.safe_request { ShopifyAPI::Product.find(:all, params: {limit: '250', page: c_page, collection_id: custom_collection}) }
						  end
						end
					end
				end
				all_custom_collections = self.safe_request { ShopifyAPI::CustomCollection.find(:all, params: {limit: '250', page: page}) }
			end

			page = 1
			count = 1
			products = self.safe_request { ShopifyAPI::Product.find(:all, params: {limit: '250', page: page}) }
			while !products.empty?
				target_shop.with_shopify_session do
					if ShopifyAPI.credit_left < 10
				    sleep 10.seconds
				  end
					products.each do |product|
						unless custom_collection_product_ids.include? product.id
						  hashed_product = JSON.parse product.to_json
						  attributes_to_remove.each {|attribute| hashed_product.delete attribute }
						  hashed_product['variants'].each do |v|
						  	v.delete 'image_id'
						  	if price_multiplier
									v['price'] = v['price'].to_i * price_multiplier if v['price'] && v['price'].to_i > 0
									v['compare_at_price'] = v['compare_at_price'] * price_multiplier if v['compare_at_price'] && v['compare_at_price'].to_i > 0
								end
						  end
						  self.safe_request { ShopifyAPI::Product.create hashed_product }
						  puts "Product # #{count} copied, API limit left: #{ShopifyAPI.credit_left}"
						  count += 1
						  if ShopifyAPI.credit_left < 10
						    sleep 10.seconds
						  end
						end
					end
				end
				products = self.safe_request { ShopifyAPI::Product.find(:all, params: {limit: '250', page: page}) }
			end
		end
	end
end
