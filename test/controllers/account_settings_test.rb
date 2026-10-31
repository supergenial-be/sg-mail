require "test_helper"

class AccountSettingsTest < ActionDispatch::IntegrationTest
  setup { @semisto = accounts(:semisto) }

  test "an admin gives the client a color, which tints the sidebar" do
    sign_in_as users(:michael)
    patch account_settings_path(account_id: @semisto.id), params: { account: { name: "Semisto", color: "sage" } }
    assert_redirected_to account_settings_path(account_id: @semisto.id)
    assert_equal "sage", @semisto.reload.color

    get account_root_path(account_id: @semisto.id)
    assert_select "body[data-client=sage][style*='--client-light: #e0ebdd']"
    assert_select "meta[name=theme-color][content='#e0ebdd']"
  end

  test "an admin removes the color" do
    @semisto.update!(color: "brick")
    sign_in_as users(:michael)
    patch account_settings_path(account_id: @semisto.id), params: { account: { name: "Semisto", color: "" } }
    assert_nil @semisto.reload.color
    get account_root_path(account_id: @semisto.id)
    assert_select "body[data-client]", count: 0
  end

  test "an unknown color or an empty name is refused" do
    sign_in_as users(:michael)
    patch account_settings_path(account_id: @semisto.id), params: { account: { name: "Semisto", color: "#ff0000" } }
    assert_response :unprocessable_entity
    patch account_settings_path(account_id: @semisto.id), params: { account: { name: " ", color: "sky" } }
    assert_response :unprocessable_entity
    assert_nil @semisto.reload.color
  end

  test "a member sees the color but cannot change it" do
    sign_in_as users(:mohammad)
    get account_settings_path(account_id: @semisto.id)
    assert_response :success
    assert_select "form[action=?]", account_settings_path(account_id: @semisto.id), count: 0
    patch account_settings_path(account_id: @semisto.id), params: { account: { name: "Autre", color: "sky" } }
    assert_equal "Semisto", @semisto.reload.name
  end
end
