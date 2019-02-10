class TicketMailer < ApplicationMailer
	default from: 'ticket@express_discounts.com'

  def ticket_email
    @user_name = params[:user_name]
    @user_email  = params[:user_email]
    @user_query = params[:user_query]
    mail(to: 'support@marbgroup.com', subject: 'New ticket')
  end
end
