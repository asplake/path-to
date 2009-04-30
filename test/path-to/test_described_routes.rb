require 'rubygems'
require 'test/unit'
require 'path-to/described_routes'

class TestDescribedRoutes < Test::Unit::TestCase
  attr_reader :app

  BASE = "http://localhost"
  
  RESOURCE_TEMPLATE_NAMES = [
      "admin_product",
      "admin_products",
      "described_route",
      "described_routes",
      "edit_admin_product",
      "edit_described_route",
      "edit_page",
      "edit_user",
      "edit_user_article",
      "edit_user_profile",
      "new_admin_product",
      "new_described_route",
      "new_page",
      "new_user",
      "new_user_article",
      "new_user_profile",
      "page",
      "pages",
      "recent_user_articles",
      "root",
      "summary_page",
      "toggle_visibility_page",
      "user",
      "user_article",
      "user_articles",
      "user_profile",
      "users"]

  def setup
    json ||= File.read(File.dirname(__FILE__) + "/fixtures/described_routes_test.json")
    @app = PathTo::DescribedRoutes::Application.new(:base => BASE, :json => json)
  end
  
  def test_resource_templates_by_name
    assert_equal(RESOURCE_TEMPLATE_NAMES, app.resource_templates_by_name.keys.sort)
    assert_kind_of(DescribedRoutes::ResourceTemplate, app.resource_templates_by_name["user"])
  end
  
  def test_app_child_class_for
    assert_equal(PathTo::DescribedRoutes::TemplatedPath, app.child_class_for(nil, nil, nil, nil))
    assert_equal(PathTo::DescribedRoutes::TemplatedPath, app.child_class_for(nil, :user, nil, nil))
  end

  def test_app_child_with_missing_params
    assert_raises(ArgumentError) do
      app.edit_user
    end
  end

  def test_app_child_with_insufficient_params
    assert_raises(ArgumentError) do
      app.user_article("user_id" => "dojo")
    end
  end

  def test_app_child_with_no_params
    assert_equal('users', app.users.resource_template.name)
  end

  def test_app_children_with_params
    assert_equal('user', app.user("user_id" => "dojo").resource_template.name)
    assert_equal('user_article', app.user_article("user_id" => "dojo", "article_id" => "first-post").resource_template.name)
  end
  
  def test_app_bad_child_name
    assert_raises(NoMethodError) do
      app.flooby
    end
  end
  
  def test_path_collection_member
    assert_equal('user', app.users["user_id" => "dojo"].resource_template.name)
  end

  def test_nested_resource
    assert_equal('user_articles', app.users["user_id" => "dojo"].articles.resource_template.name)
  end

  def test_bad_nested_resource
    assert_raises(NoMethodError) do
      app.users.users
    end
  end
  
  def test_uri_template_expansion
    assert_equal(
        "http://localhost:3000/users/dojo/articles/recent",
        app.users["user_id" => "dojo"].articles.recent.uri)
    assert_equal(
        "http://localhost:3000/users/dojo/articles/recent.json",
        app.users["user_id" => "dojo", "format" => "json"].articles.recent.uri)
  end

  def test_path_optional_params
    users_json = app.users["format" => "json"]
    user_json = app.users["user_id" => "dojo"]["format" => "json"]
    
    assert_equal("users", users_json.service)
    assert_equal("user", user_json.service)
    assert_equal("http://localhost:3000/users.json", users_json.uri)
    assert_equal("http://localhost:3000/users/dojo.json", user_json.uri)
  end

  def test_app_params
    app_json = app["format" => "json"]
    users_json = app_json.users
    
    assert_kind_of(PathTo::DescribedRoutes::Application, app_json)
    assert_equal(app, app_json.parent)
    assert_equal("http://localhost:3000/users.json", users_json.uri)
  end
end
