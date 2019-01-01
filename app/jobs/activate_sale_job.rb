class ActivateSaleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    sale = Sale.find(args[0])
    if sale.Scheduled?
		  session = sale.shop.with_shopify!
		  sale.activate_sale
		end
  end
end
