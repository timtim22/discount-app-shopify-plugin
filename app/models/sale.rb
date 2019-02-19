class Sale < ApplicationRecord
  belongs_to :shop
  has_many :sale_collection, :dependent => :delete_all

	enum sale_target: [ 'Whole Store', 'Specific collections', 'Specific products' ]
	enum sale_type: [ 'Percentage', 'Fixed Amount Off' ]
	enum status: ['Enabled', 'Disabled', 'Activating', 'Deactivating']
	validates :title, presence: true
	validates :amount, presence: true

	def activate_sale
		sale_id = self.id
		if sale_target == 'Whole Store'
			products = ShopifyAPI::Product.find(:all, params: {limit: '250', fields: "id,variants"})
			page = 1
			while !products.empty?
				products.each do |product|
					if ShopifyAPI.credit_left < 5
						sleep 10.seconds
					end
					old_price = OldPrice.find_by(sale_id: sale_id, product_id: product.id.to_s)
					if old_price.nil?
						variants = {}
						product.variants.each do |variant|
							if variant.price.to_f > 0 || variant.compare_at_price < variant.price
								if variant.compare_at_price.nil?
									variant.compare_at_price = variant.price
								end
								variants[variant.id.to_s] = variant.price
								if Percentage?
				  				variant.price = ((100-amount)*variant.price.to_f)/100
				  			else
				  				variant.price = variant.price.to_f - amount
				  			end
							end
						end
						if !variants.empty?
							old_price = OldPrice.new(sale_id: sale_id, product_id: product.id.to_s, variants: variants)
							product.save
							old_price.save
						end
					end
				end
				if products.length == 250
					page += 1
					products = ShopifyAPI::Product.find(:all, params: {limit: '250', fields: "id,variants", page: page})
				else
					products = []
				end
			end

		elsif sale_target == 'Specific collections'
			sc = SaleCollection.find_by(sale_id: sale_id)
			if sc
				collections = SaleCollection.find_by(sale_id: sale_id).collections
			else
				collections = {}
			end
			if collections.empty?
				return -1
			end
			collections.each do |collection, title|
				products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants"})
				page = 1
				while !products.empty?
					products.each do |product|
						if ShopifyAPI.credit_left < 5
							sleep 10.seconds
							puts "Sleeping"
						end
						old_price = OldPrice.find_by(sale_id: sale_id, product_id: product.id.to_s)
				    if old_price.nil?
				    	variants = {}
	    				product.variants.each do |variant|
				    		if variant.price.to_f > 0
				    			if variant.compare_at_price.nil? || variant.compare_at_price < variant.price
				    				variant.compare_at_price = variant.price
				    			end
					    		variants[variant.id.to_s] = variant.price
				    			if Percentage?
					  				variant.price = ((100-amount)*variant.price.to_f)/100
					  			else
					  				variant.price = variant.price.to_f - amount
					  			end
						  	end
			    		end
			    		if !variants.empty?
								old_price = OldPrice.new(sale_id: sale_id, product_id: product.id.to_s, variants: variants)
								product.save
								old_price.save
			    		end
			    	end
			    end
			    if products.length == 250
				    page += 1
			    	products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants", page: page})
			    else
			    	products = []
			    end
			  end
			end
		end
		return
	end

	def deactivate_sale
		sale_id = self.id
		client = ShopifyAPI::GraphQL.new
		variant_update_query = client.parse <<-'GRAPHQL'
		mutation($id: ID!, $price: Money) {
			productVariantUpdate(input: {id: $id, price: $price}) {
				productVariant{
					price
			    }
			}
		}
		GRAPHQL
		gqc = 1000
		OldPrice.where(sale_id: sale_id).find_each do |old_price|
			use_graphql = false
			if ShopifyAPI.credit_left < 5 && gqc < 200
				puts 'sleeping, no graphql or rest credits left'
				sleep 10.seconds
				use_graphql = false
			elsif ShopifyAPI.credit_left < 5
				use_graphql = true
				puts "Credits less than 5! Switching to GraphQL"
			else
				use_graphql = false
				puts "Have enough credits for REST api now!"
			end
			product = ShopifyAPI::Product.new
			product.id = old_price.product_id.to_i
			product.variants = []
			old_price.variants.each do |k,v|
				variant = ShopifyAPI::Variant.new
				variant.id = k
				variant.price = v
				product.variants.push(variant)
				if use_graphql
					result = client.query(variant_update_query, variables: {id: k, price: v})
					gqc = result.extensions["cost"]["throttleStatus"]["currentlyAvailable"]
				end
			end
			if !use_graphql
				begin
					product.save
				rescue ActiveResource::ResourceNotFound
					puts "Product has been deleted."
				end
			end
			old_price.destroy
		end
		return
  end

end