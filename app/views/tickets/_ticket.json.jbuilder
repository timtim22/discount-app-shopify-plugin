json.extract! ticket, :id, :name, :email, :query, :created_at, :updated_at
json.url ticket_url(ticket, format: :json)
