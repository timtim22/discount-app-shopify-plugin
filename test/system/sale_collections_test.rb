require "application_system_test_case"

class SaleCollectionsTest < ApplicationSystemTestCase
  setup do
    @sale_collection = sale_collections(:one)
  end

  test "visiting the index" do
    visit sale_collections_url
    assert_selector "h1", text: "Sale Collections"
  end

  test "creating a Sale collection" do
    visit sale_collections_url
    click_on "New Sale Collection"

    fill_in "Collection", with: @sale_collection.collection_id
    fill_in "Sale", with: @sale_collection.sale_id
    click_on "Create Sale collection"

    assert_text "Sale collection was successfully created"
    click_on "Back"
  end

  test "updating a Sale collection" do
    visit sale_collections_url
    click_on "Edit", match: :first

    fill_in "Collection", with: @sale_collection.collection_id
    fill_in "Sale", with: @sale_collection.sale_id
    click_on "Update Sale collection"

    assert_text "Sale collection was successfully updated"
    click_on "Back"
  end

  test "destroying a Sale collection" do
    visit sale_collections_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Sale collection was successfully destroyed"
  end
end
