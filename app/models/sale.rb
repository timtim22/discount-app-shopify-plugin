class Sale < ApplicationRecord
  belongs_to :shop
  has_many :sale_collection
  has_many :sale_products

	enum sale_target: [ 'Whole Store', 'Specific collections', 'Specific products' ]
	enum sale_type: [ 'Percentage', 'Fixed Amount Off' ]
	enum status: ['Enabled', 'Disabled', 'Scheduled']
	validates :title, presence: true
	validates :amount, presence: true

	def gather_products
		if sale_target == 'Whole Store'
			products = ShopifyAPI::Product.all
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

	def activate_sale
		products = self.gather_products

		products.each do |product|
    	product.variants.each do |variant|
    		if !variant.compare_at_price
    			variant.compare_at_price = variant.price
    		else
    			old_price = OldPrice.new
    			old_price.sale_id = id
    			old_price.variant_id = variant.id
    			old_price.old_price = variant.price
    			old_price.save
    		end
    		if Percentage?
  				variant.price = ((100-amount)*variant.price.to_f)/100
  			else
  				variant.price = variant.price.to_f - amount
  			end
    	end
    	product.save
    end
    return
	end

	def deactivate_sale
		products = self.gather_products

		products.each do |product|
    	product.variants.each do |variant|
    		if !variant.compare_at_price
    			puts "Something went wrong"    			
    		else
    			old_price = OldPrice.find_by(sale_id: id, variant_id: variant.id)
    			if old_price.nil?
	    			variant.price = variant.compare_at_price
	    			variant.compare_at_price = nil
	    		else
	    			variant.price = old_price.old_price
		    		old_price.destroy
	    		end
    		end
    	end
    	product.save
    end
    return
  end

end

