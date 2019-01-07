class SaleCollectionsController < ShopifyApp::AuthenticatedController
  before_action :set_sale_collection, only: [:show, :edit, :update, :destroy]

  # GET /sale_collections
  # GET /sale_collections.json
  def index
    @sale_collections = SaleCollection.where(sale_id: params[:format])
    @sale = Sale.find(params[:format])
    @sale_collection = SaleCollection.new
    temp = ShopifyAPI::CustomCollection.find(:all, params: {limit: '250', fields: 'id,title'})
    page = 1
    while temp.length == 250
      page += 1
      temp += ShopifyAPI::CustomCollection.find(:all, params: {limit: '250', fields: 'id,title', page: page})
    end
    @store_collections = temp
    temp = ShopifyAPI::SmartCollection.find(:all, params: {limit: '250', fields: 'id,title'})
    page = 1
    while temp.length == 250
      page += 1
      temp += ShopifyAPI::SmartCollection.find(:all, params: {limit: '250', fields: 'id,title', page: page})
    end
    @store_collections += temp
  end

  # GET /sale_collections/1
  # GET /sale_collections/1.json
  def show
  end

  # GET /sale_collections/new
  def new
    @sale_collection = SaleCollection.new
  end

  # GET /sale_collections/1/edit
  def edit
  end

  # POST /sale_collections
  # POST /sale_collections.json
  def create
    @sale_collection = SaleCollection.new(sale_collection_params)

    respond_to do |format|
      if @sale_collection.save
        format.html { redirect_to sale_collections_path(@sale_collection.sale.id), notice: 'Sale collection was successfully added.' }
        format.json { render :show, status: :created, location: @sale_collection }
      else
        format.html { render :new }
        format.json { render json: @sale_collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sale_collections/1
  # PATCH/PUT /sale_collections/1.json
  def update
    respond_to do |format|
      if @sale_collection.update(sale_collection_params)
        format.html { redirect_to @sale_collection, notice: 'Sale collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @sale_collection }
      else
        format.html { render :edit }
        format.json { render json: @sale_collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sale_collections/1
  # DELETE /sale_collections/1.json
  def destroy
    sale_id = @sale_collection.sale.id
    @sale_collection.destroy
    respond_to do |format|
      format.html { redirect_to sale_collections_path(sale_id), notice: 'Sale collection was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sale_collection
      @sale_collection = SaleCollection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def sale_collection_params
      params.require(:sale_collection).permit(:sale_id, :collection_id, :collection_title)
    end
end
