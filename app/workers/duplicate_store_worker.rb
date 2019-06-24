class DuplicateStoreWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(*args)
    shop = Shop.find(args[0])
    shop.transfer(args[1], args[2])
  end
end
