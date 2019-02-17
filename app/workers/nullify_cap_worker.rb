class NullifyCapWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, lock: :until_executed,
                  unique_args: ->(args) { [ args.first ] }

  def perform(*args)
    shop = Shop.find(args[0])
    shop.nullify_cap
  end
end
