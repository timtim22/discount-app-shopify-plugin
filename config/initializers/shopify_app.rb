ShopifyApp.configure do |config|
  config.application_name = "Express Sales by Marbgroup"
  config.api_key = ENV.fetch('SHOPIFY_API_KEY', '').presence || raise('Missing SHOPIFY_API_KEY')
  config.secret = ENV.fetch('SHOPIFY_API_SECRET', '').presence || raise('Missing SHOPIFY_API_SECRET')
  config.old_secret = ""
  config.scope = "read_products, write_products, read_product_listings"
                                 # https://help.shopify.com/en/api/getting-started/authentication/oauth/scopes
  config.embedded_app = true
  config.after_authenticate_job = false
  config.api_version = '2019-07'
  config.shop_session_repository = 'Shop'
  config.allow_jwt_authentication = true
  config.allow_cookie_authentication = false
end

# ShopifyApp::Utils.fetch_known_api_versions                        # Uncomment to fetch known api versions from shopify servers on boot
# ShopifyAPI::ApiVersion.version_lookup_mode = :raise_on_unknown    # Uncomment to raise an error if attempting to use an api version that was not previously known


#old config
# ShopifyApp.configure do |config|
#   config.application_name = "Express Sales by Marbgroup"
#   config.api_key = ENV["SHOPIFY_API_KEY"]
#   config.secret = ENV["SHOPIFY_API_SECRET"]
#   config.scope = "read_products, write_products, read_product_listings"
#   config.embedded_app = true
#   config.after_authenticate_job = false
#   # config.session_repository = 'Shop'
#   config.api_version = '2019-07'
#   # config.webhooks = [
#   #   {topic: 'app/uninstalled', address: ENV["DOMAIN"]+'/webhooks/app_uninstalled', fields: ['myshopify_domain'], format: 'json'}
#   # ]
# end
# ShopifyAPI::Base.api_version = ShopifyApp.configuration.api_version