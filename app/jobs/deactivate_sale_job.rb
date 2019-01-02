class DeactivateSaleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    sale = Sale.find(args[0])
    session = sale.shop.with_shopify!
    sale.deactivate_sale
	  return
  end
end
