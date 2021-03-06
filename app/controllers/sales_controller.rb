class SalesController < AuthenticatedController
  before_action :set_sale, only: [:show, :edit, :update, :destroy]

include ShopifyApp::EmbeddedApp
include ShopifyApp::RequireKnownShop

  def activate_charge
    recurring_application_charge = ShopifyAPI::RecurringApplicationCharge.find(request.params['charge_id'])
    if recurring_application_charge.status == "accepted"
      if recurring_application_charge.activate
        shop = Shop.find(session[:shopify])
        shop.activated = true
        shop.currency ||= ShopifyAPI::Shop.current.currency
        shop.save
        redirect_to root_url
      end
    end
  end

  def index
    @shop = Shop.find(session[:shopify])
    if @shop.activated
      if @shop.currency.nil?
        @shop.currency = ShopifyAPI::Shop.current.currency
        @shop.save
      end
      @sales = Sale.where(shop_id: @shop.id).order(:id)
    else
      recurring_application_charge = ShopifyAPI::RecurringApplicationCharge.new(
        name: "ExpressSales Monthly Charge",
        price: 8.99,
        return_url: ENV['DOMAIN']+"/activatecharge",
        trial_days: 7)
      if recurring_application_charge.save
        @ru = recurring_application_charge.confirmation_url
        render 'charge_redirect', :layout => false
      end
    end
  end

  def show
    if @sale.sale_target == "Specific collections"
      @sale_collections = SaleCollection.find_by(sale_id: @sale.id)
    end
  end

  def new
    @sale = Sale.new
    @currency = Shop.find(session[:shopify]).currency
  end

  def edit
    @sale_collections = SaleCollection.find_by(sale_id: @sale.id)
    @currency = Shop.find(session[:shopify]).currency
  end

  def create
    @sale = Sale.new(sale_params)
    @sale.shop_id = Shop.find_by(shopify_domain: session[:shopify_domain]).id
    if !@sale.scheduled
      @sale.start_time = nil
      @sale.end_time = nil
    else
      @sale.start_time = DateTime.parse(params[:sale][:parsed_start_date])
      @sale.end_time = DateTime.parse(params[:sale][:parsed_end_date]) if (params[:sale][:parsed_end_date] && !params[:sale][:parsed_end_date].blank?)
    end
    respond_to do |format|
      if @sale.save
        if @sale.sale_target == 'Specific collections' && params[:sale][:collections] != ""
          collections = JSON.parse(params[:sale][:collections])
          if !collections.empty?
            collections.each do |k,v|
              sc = SaleCollection.find_by(sale_id: @sale.id)
              if sc
                sc.update(collections: collections)
              else
                SaleCollection.create(sale_id: @sale.id, collections: collections)
              end
            end
          end
        end

        if @sale.scheduled
          ActivateSaleWorker.perform_at(@sale.start_time, @sale.id)
          DeactivateSaleWorker.perform_at(@sale.end_time, @sale.id) if @sale.end_time
        elsif @sale.Enabled?
          @sale.update(status: 2)
          ActivateSaleWorker.perform_async(@sale.id)
        end

        format.html { redirect_to sales_path, notice: 'Sale was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  def update
    if @sale.Enabled?
      check2 = true
      check = true
      if @sale.scheduled && @sale.start_time > DateTime.now && DateTime.now > @sale.end_time
        check = false
      end
    else
      check = false
      check2 = false
    end
    respond_to do |format|
      if @sale.update(sale_params)
        if @sale.sale_target == 'Specific collections'
          if params[:sale][:collections] && params[:sale][:collections] != ""
            collections = JSON.parse(params[:sale][:collections])
            if !collections.empty?
              collections.each do |k,v|
                sc = SaleCollection.find_by(sale_id: @sale.id)
                if sc
                  sc.update(collections: collections)
                else
                  SaleCollection.create(sale_id: @sale.id, collections: collections)
                end
              end
            end
          end
        end

        if !@sale.scheduled or @sale.start_time == "" or @sale.end_time == ""
          @sale.start_time = nil
          @sale.end_time = nil
        else
          @sale.start_time = DateTime.parse(params[:sale][:parsed_start_date])
          if (params[:sale][:parsed_end_date] && !params[:sale][:parsed_end_date].blank?)
            @sale.end_time = DateTime.parse(params[:sale][:parsed_end_date])
          else
            @sale.end_time = nil
          end
        end
        @sale.save
        if @sale.Enabled?
          if @sale.scheduled
            ActivateSaleWorker.perform_at(@sale.start_time, @sale.id)
            DeactivateSaleWorker.perform_at(@sale.end_time, @sale.id) if @sale.end_time
          else
            @sale.update(status: 2)
            ActivateSaleWorker.perform_async(@sale.id)

          end
        elsif @sale.Disabled? && check
          @sale.update(status: 3)
          DeactivateSaleWorker.perform_async(@sale.id)

        end
        if !@sale.Disabled? && check2
          check2 = false
        end
        format.html { redirect_to sales_path }
      else
        format.html { render :edit }
        format.json { render json: @sale.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @sale.destroy
    respond_to do |format|
      format.html { redirect_to sales_url, notice: 'Sale was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def medit
    if params[:sale_ids].nil?
      redirect_to sales_path, notice: 'Please select at least one sale to apply that action to.'
      return
    end
    if params[:commit] == "Activate"
      Sale.find(params[:sale_ids]).each do |sale|
        if sale.Disabled?
          if sale.scheduled
            sale.update(status: 0)
            ActivateSaleWorker.perform_at(sale.start_time, sale.id)
            DeactivateSaleWorker.perform_at(sale.end_time, sale.id)
          else
            sale.update(status: 2)
            ActivateSaleWorker.perform_async(sale.id)
          end
        elsif sale.Activating? || sale.Deactivating?
          redirect_to sales_path, notice: 'Can not modify a sale that is being processed.'
          return
        end
      end
    elsif params[:commit] == "Deactivate"
      Sale.find(params[:sale_ids]).each do |sale|
        if sale.Enabled?
          sale.update(status: 3)
          DeactivateSaleWorker.perform_async(sale.id)

        elsif sale.Activating? || sale.Deactivating?
          redirect_to sales_path, notice: 'Can not modify a sale that is being processed.'
          return
        end
      end
    elsif params[:commit] == "Delete"
      Sale.find(params[:sale_ids]).each do |sale|
        if sale.Disabled?
          sale.destroy
        elsif sale.Activating? || sale.Deactivating?
          redirect_to sales_path, notice: 'Can not modify a sale that is being processed.'
          return
        else
          redirect_to sales_path, notice: 'Can not delete an active sale.'
          return
        end
      end
    end
    redirect_to sales_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sale
      @sale = Sale.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sale_params
      params.require(:sale).permit(:title, :sale_target, :amount, :sale_type, :start_time, :end_time, :status, :scheduled)
    end
end
