require "application_system_test_case"

class SaleProductsTest < ApplicationSystemTestCase
  setup do
    @sale_product = sale_products(:one)
  end

  test "visiting the index" do
    visit sale_products_url
    assert_selector "h1", text: "Sale Products"
  end

  test "creating a Sale product" do
    visit sale_products_url
    click_on "New Sale Product"

    fill_in "Product", with: @sale_product.product_id
    fill_in "Sale", with: @sale_product.sale_id
    click_on "Create Sale product"

    assert_text "Sale product was successfully created"
    click_on "Back"
  end

  test "updating a Sale product" do
    visit sale_products_url
    click_on "Edit", match: :first

    fill_in "Product", with: @sale_product.product_id
    fill_in "Sale", with: @sale_product.sale_id
    click_on "Update Sale product"

    assert_text "Sale product was successfully updated"
    click_on "Back"
  end

  test "destroying a Sale product" do
    visit sale_products_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Sale product was successfully destroyed"
  end
end
