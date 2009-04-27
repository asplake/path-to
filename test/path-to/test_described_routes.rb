# TODO fix these
$:.push('/Users/asplake/ruby/path-to/lib')
$:.push('/Users/asplake/ruby/described_routes/lib')
$:.push('/Users/asplake/ruby/addressable/lib')

require 'rubygems'
require 'test/unit'
require 'path-to/described_routes'

class TestDescribedRoutes < Test::Unit::TestCase
  attr_reader :app

  BASE = "http://localhost"
  
  RESOURCE_TEMPLATE_NAMES = [
    "admin_product", "admin_products", "edit_admin_product", "edit_page", "edit_user", "edit_user_article",
    "edit_user_profile", "new_admin_product", "new_page", "new_user", "new_user_article", "new_user_profile",
    "page", "pages", "recent_user_articles", "root", "summary_page", "toggle_visibility_page", "user",
    "user_article", "user_articles", "user_profile", "users"]

  def setup
    @json ||= File.read(File.dirname(__FILE__) + "/fixtures/described_routes_test.json")
    resource_templates = DescribedRoutes.parse_json(@json)
    @app = PathTo::DescribedRoutes::Application.new(resource_templates, BASE)
  end
  
  def test_resource_templates_by_name
    assert_equal(RESOURCE_TEMPLATE_NAMES, app.resource_templates_by_name.keys.sort)
    assert_kind_of(DescribedRoutes::ResourceTemplate, app.resource_templates_by_name["user"])
  end
  
  def test_child_class_for
    assert_equal(PathTo::DescribedRoutes::TemplatedPath, app.child_class_for(nil, nil, nil, nil))
    assert_equal(PathTo::DescribedRoutes::TemplatedPath, app.child_class_for(nil, :user, nil, nil))
  end

  def test_child_with_missing_params
    assert_raises(ArgumentError) do
      app.edit_user
    end
  end

  def test_child_with_insufficient_params
    assert_raises(ArgumentError) do
      app.user_article("user_id" => "dojo")
    end
  end

  def test_child_with_no_params
    assert_kind_of(PathTo::DescribedRoutes::TemplatedPath, app.users)
  end

  def test_children_with_params
    assert_kind_of(PathTo::DescribedRoutes::TemplatedPath, app.user("user_id" => "dojo"))
    assert_kind_of(PathTo::DescribedRoutes::TemplatedPath, app.user_article("user_id" => "dojo", "article_id" => "first-post"))
  end
end
