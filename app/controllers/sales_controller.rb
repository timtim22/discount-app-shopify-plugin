class SalesController < ShopifyApp::AuthenticatedController
  before_action :set_sale, only: [:show, :edit, :update, :destroy]

  # GET /sales
  # GET /sales.json
  def index
    @shop = ShopifyAPI::Shop.current
    @sales = Sale.where(shop_id: Shop.find_by(shopify_domain: @shop.myshopify_domain).id)
  end

  # GET /sales/1
  # GET /sales/1.json
  def show
    if @sale.sale_target == "Specific collections"
      @sale_collection = SaleCollection.new
      @sale_collections = SaleCollection.where(sale_id: @sale.id)
    end
  end

  # GET /sales/new
  def new
    @sale = Sale.new
    @currency = ShopifyAPI::Shop.current.currency
  end

  # GET /sales/1/edit
  def edit
    @sale_collections = SaleCollection.where(sale_id: @sale.id)
  end

  # POST /sales
  # POST /sales.json
  def create
    @sale = Sale.new(sale_params)
    @sale.shop_id = Shop.find_by(shopify_domain: session[:shopify_domain]).id
    if !@sale.scheduled
      @sale.start_time = nil
      @sale.end_time = nil
    else
      @sale.start_time = DateTime.strptime(params[:sale][:start_date]+params[:sale][:start_time], '%m/%d/%Y%I:%M %p')
      @sale.end_time = DateTime.strptime(params[:sale][:end_date]+params[:sale][:end_time], '%m/%d/%Y%I:%M %p')
    end
    respond_to do |format|
      if @sale.save
        if @sale.sale_target == 'Specific collections'
          collections = params[:sale][:collections]
          list = collections.split("$;$")
          list.each do |collection|
            sc = SaleCollection.new
            sc.collection_id, sc.collection_title = collection.split("$,$")
            sc.sale_id = @sale.id
            sc.save
          end
        end

        if @sale.scheduled
          ActivateSaleJob.set(wait_until: @sale.start_time).perform_later(@sale.id)
          DeactivateSaleJob.set(wait_until: @sale.end_time).perform_later(@sale.id)
        elsif @sale.Enabled?
          ActivateSaleJob.perform_later(@sale.id)
          @sale.update(status: 2)
        end

        format.html { redirect_to sales_path, notice: 'Sale was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /sales/1
  # PATCH/PUT /sales/1.json
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
          collections = params[:sale][:collections]
          if !collections.empty?
            SaleCollection.where(sale_id: @sale.id).destroy_all
            list = collections.split("$;$")
            list.each do |collection|
              sc = SaleCollection.new
              sc.collection_id, sc.collection_title = collection.split("$,$")
              sc.sale_id = @sale.id
              sc.save
            end
          end
        end

        if !@sale.scheduled
          @sale.start_time = nil
          @sale.end_time = nil
        else
          @sale.start_time = DateTime.strptime(params[:sale][:start_time], '%m/%d/%Y %I:%M %p')
          @sale.end_time = DateTime.strptime(params[:sale][:end_time], '%m/%d/%Y %I:%M %p')
        end
        @sale.save
        if @sale.Enabled?
          if @sale.scheduled
            ActivateSaleJob.set(wait_until: @sale.start_time).perform_later(@sale.id)
            DeactivateSaleJob.set(wait_until: @sale.end_time).perform_later(@sale.id)
          else
            ActivateSaleJob.perform_later(@sale.id)
            @sale.update(status: 2)
          end
        elsif @sale.Disabled? && check
          DeactivateSaleJob.perform_later(@sale.id)
          @sale.update(status: 3)
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

  # DELETE /sales/1
  # DELETE /sales/1.json
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
            ActivateSaleJob.set(wait_until: sale.start_time).perform_later(sale.id)
            DeactivateSaleJob.set(wait_until: sale.end_time).perform_later(sale.id)
            sale.update(status: 0)
          else
            ActivateSaleJob.perform_later(sale.id)
            sale.update(status: 2)
          end
        elsif sale.Activating? || sale.Deactivating?
          redirect_to sales_path, notice: 'Can not modify a sale that is being processed.'
          return
        end
      end
    elsif params[:commit] == "Deactivate"
      Sale.find(params[:sale_ids]).each do |sale|
        if sale.Enabled?
          DeactivateSaleJob.perform_later(sale.id)
          sale.update(status: 3)
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
