class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def safe_request
    max_retries = 3
    begin
      yield
    rescue ActiveResource::ResourceInvalid => error
      puts 'Skiping invalid resource.'
    rescue ActiveResource::ClientError => error
      retries ||= 0
      if retries < max_retries
        retries += 1
        puts "sleeping retry # #{retries}"
        sleep (retries*20).seconds
        retry
      else
        raise error
      end
    rescue ActiveResource::ServerError => error
      puts 'Server Error'
      retries ||= 0
      if retries < max_retries
        retries += 1
        retry
      else
        raise error
      end
    end
  end
end
