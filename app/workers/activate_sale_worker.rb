class ActivateSaleWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, lock: :while_executing, on_conflict: :reschedule, unique_across_workers: true,
                  unique_args: :unique_args

  def self.unique_args(args)
    Sale.find(args[0]).shop_id
    puts 'Rescheduling for later by unique args'
  end

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
