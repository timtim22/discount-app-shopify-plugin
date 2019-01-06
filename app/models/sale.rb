class Sale < ApplicationRecord
  belongs_to :shop
  has_many :sale_collection, :dependent => :delete_all
  has_many :sale_products, :dependent => :delete_all

	enum sale_target: [ 'Whole Store', 'Specific collections', 'Specific products' ]
	enum sale_type: [ 'Percentage', 'Fixed Amount Off' ]
	enum status: ['Enabled', 'Disabled', 'Scheduled']
	validates :title, presence: true
	validates :amount, presence: true
=begin
	def gather_products
		if sale_target == 'Whole Store'
			products = ShopifyAPI::Product.find(:all, :params => {:limit => 250})
		elsif sale_target == 'Specific collections'
			collections = ShopifyAPI::CustomCollection.where(id: SaleCollection.where(sale_id: id).pluck(:collection_id))
			if collections.empty?
				return -1
			end
			products = []
			collections.each do |collection|
				products = products + collection.products
			end

		elsif sale_target == 'Specific products'
			products = ShopifyAPI::Product.where(id: SaleProduct.where(sale_id: id).pluck(:product_id))
			if sale_products.empty?
				return -1
			end 
		end
		products
	end

	def remove_from_sale(products)
		products.each do |product|
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
	  return
	end

	def put_on_sale(products)
		products.each do |product|
			to_save = false
    	product.variants.each do |variant|
    		if variant.price.to_f > 0
    			variant.compare_at_price = variant.price
	    		old_price = OldPrice.find_by(sale_id: id, variant_id: variant.id.to_s)
	    		if old_price.nil?
	    			old_price = OldPrice.new(sale_id: id, variant_id: variant.id.to_s, old_price: variant.price).save
		    		if Percentage?
		  				variant.price = ((100-amount)*variant.price.to_f)/100
		  			else
		  				variant.price = variant.price.to_f - amount
		  			end
		  			to_save = true
		  		else
		  			variant.price = old_price.old_price
			  	end
		  	end
    	end
    	if to_save
    		product.save
    	end
    end
    return
	end
=end
	def activate_sale
		if sale_target == 'Whole Store'
			variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price"})
			page = 1
			while !variants.empty?
				variants.each do |variant|
					if ShopifyAPI.credit_maxed?
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
				page += 1
				variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price", page: page})
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
						if ShopifyAPI.credit_maxed?
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
			    page += 1
		    	products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants", page: page})
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
					if ShopifyAPI.credit_maxed?
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
				page += 1
				variants = ShopifyAPI::Variant.find(:all, params: {limit: "250", fields: "id,price,compare_at_price", page: page})
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
						if ShopifyAPI.credit_maxed?
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
			    page += 1
		    	products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants", page: page})
			  end
			end
		end
		return
  end

end