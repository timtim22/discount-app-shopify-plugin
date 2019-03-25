# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::LoginProtection

    def callback
      if auth_hash

          login_shop
          install_webhooks
          install_scripttags
          perform_after_authenticate_job
        if !Shop.find_by(shopify_domain: shop_name).activated
          create_recurring_application_charge
        end

      else
        flash[:error] = I18n.t('could_not_log_in')
        redirect_to login_url
      end
      format.js { head :no_content }
    end

    private

    def create_recurring_application_charge
      ShopifyAPI::Base.activate_session(ShopifyAPI::Session.new(shop_name, token))
      current_charge = ShopifyAPI::RecurringApplicationCharge.current
      if current_charge.nil? || current_charge.status != "accepted"
        recurring_application_charge = ShopifyAPI::RecurringApplicationCharge.new(
                name: "ExpressSales Monthly Charge",
                price: 8.99,
                return_url: ENV['DOMAIN']+"/activatecharge",
                trial_days: 4)

        if recurring_application_charge.save
          redirect_to recurring_application_charge.confirmation_url
        end
      else
        if current_charge && current_charge.status == "accepted"
          Shop.find_by(shopify_domain: shop_name).update(activated: true)
        end
        redirect_to return_address
      end
    end

    def login_shop
      reset_session_options
      set_shopify_session
    end

    def auth_hash
      request.env['omniauth.auth']
    end

    def shop_name
      auth_hash.uid
    end

    def associated_user
      return unless auth_hash['extra'].present?

      auth_hash['extra']['associated_user']
    end

    def token
      auth_hash['credentials']['token']
    end

    def reset_session_options
      request.session_options[:renew] = true
      session.delete(:_csrf_token)
    end

    def set_shopify_session
      session_store = ShopifyAPI::Session.new(shop_name, token)

      session[:shopify] = ShopifyApp::SessionRepository.store(session_store)
      session[:shopify_domain] = shop_name
      session[:shopify_user] = associated_user if associated_user.present?
    end

    def install_webhooks
      return unless ShopifyApp.configuration.has_webhooks?

      WebhooksManager.queue(
        shop_name,
        token,
        ShopifyApp.configuration.webhooks
      )
    end

    def install_scripttags
      return unless ShopifyApp.configuration.has_scripttags?

      ScripttagsManager.queue(
        shop_name,
        token,
        ShopifyApp.configuration.scripttags
      )
    end

    def perform_after_authenticate_job
      config = ShopifyApp.configuration.after_authenticate_job

      return unless config && config[:job].present?

      if config[:inline] == true
        config[:job].perform_now(shop_domain: session[:shopify_domain])
      else
        config[:job].perform_later(shop_domain: session[:shopify_domain])
      end
    end
  end
end
