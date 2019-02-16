class ActivateSaleWorker
  include Sidekiq::Worker
	sidekiq_options retry: 3

  def perform(*args)
    sale = Sale.find(args[0])
    if !sale.Disabled? && !sale.Deactivating?
      if !sale.Activating?
        sale.update(status: 2)
      end
		  session = sale.shop.with_shopify!
		  sale.activate_sale
		end
    sale.update(status: 0)
	  return
  end
end
