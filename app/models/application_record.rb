class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def safe_request
    max_retries = 3
    retries = 0
    begin
      yield
    rescue ActiveResource::ResourceInvalid => error
      puts "An error of type #{error.class} happened, message is #{error.message}"
      puts 'Skiping invalid resource.'
    rescue ActiveResource::ClientError => error
      puts "An error of type #{error.class} happened, message is #{error.message}"
      if retries < max_retries
        retries += 1
        puts "sleeping retry # #{retries}"
        sleep (retries*20).seconds
        retry
      else
        raise error
      end
    rescue ActiveResource::ServerError => error
      puts "An error of type #{error.class} happened, message is #{error.message}"
      puts 'Server Error'
      if retries < max_retries
        retries += 1
        retry
      else
        raise error
      end
    rescue Exception => ex
      puts "An error of type #{ex.class} happened, message is #{ex.message}"
      if retries < max_retries
        retries += 1
        sleep (retries*20).seconds
        retry
      else
        raise error
      end
    end
  end
end
