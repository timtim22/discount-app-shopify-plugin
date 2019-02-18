class DeactivateSaleWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, lock: :while_executing, on_conflict: :reschedule, unique_across_workers: true,
                  unique_args: :unique_args

  def self.unique_args(args)
    Sale.find(args[0]).shop_id
  end

  def perform(*args)
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
