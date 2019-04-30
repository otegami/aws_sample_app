require 'test_helper'

class UsersEditTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  def setup
    @user = users(:michael)
  end  
  
  
  test "unsuccessful edit" do
    get edit_user_path(@user)
    assert_template 'users/edit'
    patch user_path(@user), params: { user: {
                                        name: "",
                                        email: "foo@invalid",
                                        password: "foo",
                                        password_confirmation: "bar"
                                      }
                                    }
    assert_template 'users/edit'
    assert_select 'div#error_explanation'
    assert_select 'div.alert', 'The form contains 3 errors.'
    assert_select 'div.alert-danger'
  end
  
  test "successful edit" do
    get edit_user_path(@user)
    assert_template 'users/edit'
    name = "Foobar"
    email = "foo@bar.com"
    patch user_path(@user), params: { user: { 
                                        name: name,
                                        email: email,
                                        password: "",
                                        password_confirmation: ""
                                      }
                                    }
    assert_not flash.empty?
    assert_redirected_to @user
    @user.reload
    assert_equal name, @user.name
    assert_equal email, @user.email
  end  
end
