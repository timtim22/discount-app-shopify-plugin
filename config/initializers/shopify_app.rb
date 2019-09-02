ShopifyApp.configure do |config|
  config.application_name = "Express Sales by Marbgroup"
  config.api_key = ENV["SHOPIFY_API_KEY"]
  config.secret = ENV["SHOPIFY_API_SECRET"]
  config.scope = "read_products, write_products, read_product_listings"
  config.embedded_app = true
  config.after_authenticate_job = false
  config.session_repository = 'Shop'
  config.api_version = '2019-07'
  config.webhooks = [
    {topic: 'app/uninstalled', address: ENV["DOMAIN"]+'/webhooks/app_uninstalled', fields: ['myshopify_domain'], format: 'json'}
  ]
end
ShopifyAPI::Base.api_version = ShopifyApp.configuration.api_version
