class DeactivateSaleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    sale = Sale.find(args[0])
    if sale.Disabled? && sale.scheduled && OldPrice.find_by(sale_id: sale.id).nil?
	  	return
	  end
	  session = sale.shop.with_shopify!
	  sale.deactivate_sale
	  return
  end
end
