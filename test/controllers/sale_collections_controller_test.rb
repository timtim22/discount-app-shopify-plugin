require 'test_helper'

class SaleCollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sale_collection = sale_collections(:one)
  end

  test "should get index" do
    get sale_collections_url
    assert_response :success
  end

  test "should get new" do
    get new_sale_collection_url
    assert_response :success
  end

  test "should create sale_collection" do
    assert_difference('SaleCollection.count') do
      post sale_collections_url, params: { sale_collection: { collection_id: @sale_collection.collection_id, sale_id: @sale_collection.sale_id } }
    end

    assert_redirected_to sale_collection_url(SaleCollection.last)
  end

  test "should show sale_collection" do
    get sale_collection_url(@sale_collection)
    assert_response :success
  end

  test "should get edit" do
    get edit_sale_collection_url(@sale_collection)
    assert_response :success
  end

  test "should update sale_collection" do
    patch sale_collection_url(@sale_collection), params: { sale_collection: { collection_id: @sale_collection.collection_id, sale_id: @sale_collection.sale_id } }
    assert_redirected_to sale_collection_url(@sale_collection)
  end

  test "should destroy sale_collection" do
    assert_difference('SaleCollection.count', -1) do
      delete sale_collection_url(@sale_collection)
    end

    assert_redirected_to sale_collections_url
  end
end
