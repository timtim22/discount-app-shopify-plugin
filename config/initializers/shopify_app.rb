ShopifyApp.configure do |config|
  config.application_name = "My Shopify App"
  config.api_key = ENV["SHOPIFY_API_KEY"]
  config.secret = ENV["SHOPIFY_API_SECRET"]
  config.scope = "read_products, write_products, read_product_listings" # Consult this page for more scope options:
                                 # https://help.shopify.com/en/api/getting-started/authentication/oauth/scopes
  config.embedded_app = true
  config.after_authenticate_job = false
  config.session_repository = Shop
end
