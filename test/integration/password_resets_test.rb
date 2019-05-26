require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end  
  
  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # post wrong email
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # post valid email
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # form test about resets_password_form
    user = assigns(:user)
    # invalid user
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # valid email and invalid token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # valid email and token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # invalid password and password_confirmaiton
    patch password_reset_path(user.reset_token),
      params: { 
        email: user.email,
        user: {
          password: "",
          passwrod_confirmation: ""
        }
      }
    assert_select 'div#error_explanation'
    # valid password and confirmation
    patch password_reset_path(user.reset_token),
      params: { 
        email: user.email,
        user: {
          password: "foobaz",
          passwrod_confirmation: "foobaz"
        }
      }
    assert is_logged_in?
    # user.reload
    # assert_nill user.reset_digest
    assert_not flash.empty?
    assert_redirected_to user
  end
  
  test "expired token" do
    get new_password_reset_path
    post password_resets_path,
      params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
      params: { 
          email: @user.email,
          user: {
            password: "foobar",
            passwrod_confirmation: "foobar"
          }
        }
    assert_response :redirect
    follow_redirect!
    assert_match /expired/i, response.body
  end  
end
