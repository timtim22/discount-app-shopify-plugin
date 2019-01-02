class SalesController < ShopifyApp::AuthenticatedController
  before_action :set_sale, only: [:show, :edit, :update, :destroy]

  # GET /sales
  # GET /sales.json
  def index
    @sales = Sale.where(shop_id: Shop.find_by(shopify_domain: ShopifyAPI::Shop.current.myshopify_domain).id)
  end

  # GET /sales/1
  # GET /sales/1.json
  def show
    if @sale.sale_target == "Specific collections"
      @sale_collection = SaleCollection.new
      @sale_collections = SaleCollection.where(sale_id: @sale.id)
    elsif @sale.sale_target == "Specific products"
      @sale_product = SaleProduct.new
      @sale_products = SaleProduct.where(sale_id: @sale.id)
    end
  end

  # GET /sales/new
  def new
    @sale = Sale.new
  end

  # GET /sales/1/edit
  def edit
  end

  # POST /sales
  # POST /sales.json
  def create
    @sale = Sale.new(sale_params)
    @sale.shop_id = Shop.find_by(shopify_domain: ShopifyAPI::Shop.current.domain).id
    if !@sale.Scheduled?
      @sale.start_time = nil
      @sale.end_time = nil
    end
    respond_to do |format|
      if @sale.save
        if @sale.Enabled?
          ActivateSaleJob.perform_later(@sale.id)
        elsif @sale.Scheduled?
          ActivateSaleJob.set(wait_until: @sale.start_time).perform_later(@sale.id)
          DeactivateSaleJob.set(wait_until: @sale.end_time).perform_later(@sale.id)
        end
        format.html { redirect_to @sale, notice: 'Sale was successfully created.' }
        format.json { render :show, status: :created, location: @sale }
      else
        format.html { render :new }
        format.json { render json: @sale.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sales/1
  # PATCH/PUT /sales/1.json
  def update
    if @sale.Enabled? || (@sale.Scheduled? && @sale.start_time < DateTime.now && DateTime.now < @sale.end_time)
      check = true
    else 
      check = false
    end
    respond_to do |format|
      if @sale.update(sale_params)
        if !@sale.Scheduled?
          @sale.start_time = nil
          @sale.end_time = nil
        end
        @sale.save
        if @sale.Enabled?
          ActivateSaleJob.perform_later(@sale.id)
        elsif @sale.Scheduled?
          ActivateSaleJob.set(wait_until: @sale.start_time).perform_later(@sale.id)
          DeactivateSaleJob.set(wait_until: @sale.end_time).perform_later(@sale.id)
        elsif @sale.Disabled? && check
          DeactivateSaleJob.perform_later(@sale.id)        
        end
        format.html { redirect_to @sale, notice: 'Sale was successfully updated.' }
        format.json { render :show, status: :ok, location: @sale }
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
