class DeactivateSaleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    sale = Sale.find(args[0])
    if sale.Disabled? && sale.scheduled && OldPrice.find_by(sale_id: sale.id).nil?
	  	return
	  end
    if !sale.Deactivating?
      sale.update(status: 3)
    end
	  session = sale.shop.with_shopify!
	  sale.deactivate_sale
	  sale.update(status: 1)
    return
  end
end
