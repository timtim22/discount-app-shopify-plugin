class ShopsController < ApplicationController
  include ShopifyApp::WebhookVerification

  def uninstall
    Shop.find_by(shopify_domain: params[:myshopify_domain]).destroy
    render json: {success: true}
  end
end
