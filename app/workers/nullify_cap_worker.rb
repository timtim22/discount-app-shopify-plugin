class NullifyCapWorker
  include Sidekiq::Worker

  def perform(*args)
    shop = Shop.find(args[0])
    shop.nullify_cap
  end
end
