ShopifyApp.configure do |config|
  config.application_name = "My Shopify App"
  config.api_key = "9264137e8ed777a05724042963f715e6"
  config.secret = "28ad444ba36c0817a57f8a48308b7d6b"
  config.scope = "read_products, write_products, read_product_listings" # Consult this page for more scope options:
                                 # https://help.shopify.com/en/api/getting-started/authentication/oauth/scopes
  config.embedded_app = true
  config.after_authenticate_job = false
  config.session_repository = Shop
end
