class Sale
  include Mongoid::Document
  include Mongoid::Timestamps

  field :shop_id, type: Integer
  field :title, type: String
  field :sale_target, type: Integer, default: 0
  field :amount, type: Float
  field :sale_type, type: Integer, default: 0
  field :status, type: Integer, default: 1
  field :scheduled, type: Mongoid::Boolean, default: false
  field :start_time, type: DateTime
  field :end_time, type: DateTime


  belongs_to :shop
  has_one :sale_collection, :dependent => :destroy
  has_many :old_price, :dependent => :delete_all

	# enum sale_target: [ 'Whole Store', 'Specific collections', 'Specific products' ]
	# enum sale_type: [ 'Percentage', 'Fixed Amount Off' ]
	# enum status: ['Enabled', 'Disabled', 'Activating', 'Deactivating']
	validates :title, presence: true
	validates :amount, presence: true

	def activate_sale
		sale_id = self.id
		if sale_target == 'Whole Store'
			products = ShopifyAPI::Product.find(:all, params: {limit: '250', fields: "id,variants"})

			loop do
				products.each do |product|
					old_price = OldPrice.find_by(sale_id: sale_id, product_id: product.id.to_s)
					if old_price.nil?
						variants = {}
						product.variants.each do |variant|
							if variant.price.to_f > 0 || (variant.compare_at_price && variant.compare_at_price < variant.price)
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

							if product.save
								old_price.save
							else
								p product.errors.messages
							end
						end
						sleep 10.seconds if ShopifyAPI.credit_left < 5
					end
				end
				break unless products.next_page?
				products = products.fetch_next_page
				sleep 10.seconds if ShopifyAPI.credit_left < 5
			end

		elsif sale_target == 'Specific collections'
			sc = SaleCollection.find_by(sale_id: sale_id)
			if sc
				collections = sc.collections.keys
			else
				collections = []
			end
			if collections.empty?
				return -1
			end
			collections.each do |collection|
				products = ShopifyAPI::Product.find(:all, params: {collection_id: collection, limit: "250", fields: "id, variants"})

				loop do
					products.each do |product|
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
							sleep 10.seconds if ShopifyAPI.credit_left < 10
			    	end
			    end
			    break unless products.next_page?
					products = products.fetch_next_page
					sleep 10.seconds if ShopifyAPI.credit_left < 5
			  end
			end
		end
		return
	end

	def deactivate_sale
		sale_id = self.id
		OldPrice.where(sale_id: sale_id).find_each do |old_price|
			if ShopifyAPI.credit_left < 5
				puts 'sleeping, low on rest credits'
				sleep 10.seconds
			end
			product = ShopifyAPI::Product.new
			product.id = old_price.product_id.to_i
			product.variants = []
			old_price.variants.each do |k,v|
				variant = ShopifyAPI::Variant.new
				variant.id = k
				variant.price = v
				product.variants.push(variant)
			end
			begin
				product.save
			rescue ActiveResource::ResourceNotFound
				puts "Product has been deleted."
			end
			old_price.destroy
		end
		return
  end

end
