json.extract! sale, :id, :title, :target, :amount, :type, :start_time, :end_time, :status, :scheduled, :created_at, :updated_at
json.url sale_url(sale, format: :json)
