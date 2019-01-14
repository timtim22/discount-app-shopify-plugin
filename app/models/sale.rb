class Sale < ApplicationRecord
  belongs_to :shop
  has_many :sale_collection, :dependent => :delete_all

	enum sale_target: [ 'Whole Store', 'Specific collections', 'Specific products' ]
	enum sale_type: [ 'Percentage', 'Fixed Amount Off' ]
	enum status: ['Enabled', 'Disabled', 'Activating', 'Deactivating']
	validates :title, presence: true
	validates :amount, presence: true

	def activate_sale
		if sale_target == 'Whole Store'
			products = ShopifyAPI::Product.find(:all, params: {limit: '250', fields: "id,variants"})
			page = 1
			while !products.empty?
				products.each do |product|
					if ShopifyAPI.credit_left < 5
						sleep 10.seconds
					end
					old_price = OldPrice.find_by(sale_id: id, product_id: product.id.to_s)
					if old_price.nil?
						variants = {}
						product.variants.each do |variant|
							if variant.price.to_f > 0
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
						old_price = OldPrice.new(sale_id: id, product_id: product.id.to_s, variants: variants)
						product.save
						old_price.save
					end
				end
				if products.length == 250
					page += 1
					products = ShopifyAPI::Product.find(:all, params: {limit: '250', fields: "id,variants" page: page})
				else
					products = []
				end
			end
=begin
			variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price"})
			page = 1
			while !variants.empty?
				variants.each do |variant|
					if ShopifyAPI.credit_left < 5
						sleep 10.seconds
						puts "Sleeping"
					end
					if variant.price.to_f > 0
						if variant.compare_at_price.nil?
	    				variant.compare_at_price = variant.price
	    			end
		    		old_price = OldPrice.find_by(sale_id: id, variant_id: variant.id.to_s)
		    		if old_price.nil?
		    			old_price = OldPrice.new(sale_id: id, variant_id: variant.id.to_s, old_price: variant.price).save
			    		if Percentage?
			  				variant.price = ((100-amount)*variant.price.to_f)/100
			  			else
			  				variant.price = variant.price.to_f - amount
			  			end
			  			variant.save
			  		elsif variant.price.to_f == old_price.old_price
			  			if Percentage?
			  				variant.price = ((100-amount)*variant.price.to_f)/100
			  			else
			  				variant.price = variant.price.to_f - amount
			  			end
			  			variant.save
				  	end
			  	end
				end
				if variants.length == 250
					page += 1
					variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price", page: page})
				else
					variants = []
				end
			end
=end
			
		elsif sale_target == 'Specific collections'
			collections = SaleCollection.where(sale_id: id).pluck(:collection_id)
			if collections.empty?
				return -1
			end
			collections.each do |collection|
				products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants"})
				page = 1
				while !products.empty?
					products.each do |product|
						if ShopifyAPI.credit_left < 5
							sleep 10.seconds
							puts "Sleeping"
						end
						to_save = false
	    			product.variants.each do |variant|
			    		if variant.price.to_f > 0
			    			if variant.compare_at_price.nil? || variant.compare_at_price < variant.price
			    				variant.compare_at_price = variant.price
			    			end
				    		old_price = OldPrice.find_by(sale_id: id, variant_id: variant.id.to_s)
				    		if old_price.nil?
				    			old_price = OldPrice.new(sale_id: id, variant_id: variant.id.to_s, old_price: variant.price).save
					    		if Percentage?
					  				variant.price = ((100-amount)*variant.price.to_f)/100
					  			else
					  				variant.price = variant.price.to_f - amount
					  			end
					  			to_save = true
					  		elsif variant.price.to_f == old_price.old_price
					  			if Percentage?
					  				variant.price = ((100-amount)*variant.price.to_f)/100
					  			else
					  				variant.price = variant.price.to_f - amount
					  			end
					  			to_save = true
						  	end
					  	end
			    	end
			    	if to_save
			    		product.save
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
		if sale_target == 'Whole Store'
			variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price"})
			page = 1
			while !variants.empty?
				variants.each do |variant|
					if ShopifyAPI.credit_left < 5
						sleep 10.seconds
						puts "Sleeping"
					end
					if !variant.compare_at_price
		  			puts "Something went wrong"    			
		  		else
		  			old_price = OldPrice.find_by(sale_id: id, variant_id: variant.id.to_s)
		  			if !old_price.nil?
		    			variant.price = old_price.old_price
		    			variant.save
			    		old_price.destroy
		    		end
		  		end
				end
				if variants.length == 250
					page += 1
					variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price", page: page})
				else
					variants = []
				end
			end

		elsif sale_target == 'Specific collections'
			collections = SaleCollection.where(sale_id: id).pluck(:collection_id)
			if collections.empty?
				return -1
			end
			collections.each do |collection|
				products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants"})
				page = 1
				while !products.empty?
					products.each do |product|
						if ShopifyAPI.credit_left < 5
							sleep 10.seconds
							puts "Sleeping"
						end
						to_save = false
	    			product.variants.each do |variant|
			    		if !variant.compare_at_price
				  			puts "Something went wrong"    			
				  		else
				  			old_price = OldPrice.find_by(sale_id: id, variant_id: variant.id.to_s)
				  			if !old_price.nil?
				    			variant.price = old_price.old_price
				    			to_save = true
					    		old_price.destroy
				    		end
				  		end
			    	end
			    	if to_save
			    		product.save
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

end