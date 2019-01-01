class HomeController < ShopifyApp::AuthenticatedController
  def index
   
    @webhooks = ShopifyAPI::Webhook.find(:all)
 
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    @info = ""
    @products.each do |product|
    	product.variants.each do |variant|
    		if variant.compare_at_price
    			variant.price = variant.compare_at_price
    			variant.compare_at_price = nil
    		end
    		@info += "Variant_id: " + variant.id.to_s + "Price: " + variant.price.to_s
    	end
    	product.save
    end
  end
end
