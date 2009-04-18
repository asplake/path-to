require "test/unit"
require "path-to/application"

module PathTo
  class TestApplication < Test::Unit::TestCase
    attr_reader :simple_app, :bigger_app
    
    class Users < Path
      def [](user)
        super(:user => user)
      end
    end
    
    class Articles < Path
      def [](slug)
        super(:slug => slug)
      end
    end
    
    def setup
      @simple_app = Application.new(:users => "http://example.com/users/{user}")
      
      @bigger_app = Application.new(
          :users    => "http://example.com/users/{user}",
          :articles => "http://example.com/users/{user}/articles/{slug}") do |app|
        def app.child_class_for(instance, method, params)
          {
            :users    => Users,
            :articles => Articles
          }[method]
        end
      end
    end
  
    def test_uri_for
      assert_equal("http://example.com/users/", simple_app.uri_for(:users))
      assert_equal("http://example.com/users/", simple_app.uri_for(:users, :what => "ever"))
      assert_equal("http://example.com/users/dojo", simple_app.uri_for(:users, :user => "dojo"))
    end
  
    def test_child_uri
      assert_equal("http://example.com/users/", simple_app.users.uri)
      assert_equal("http://example.com/users/", simple_app.users(:what => "ever").uri)
      assert_equal("http://example.com/users/", simple_app.users[:what => "ever"].uri)
      assert_equal("http://example.com/users/dojo", simple_app.users(:user => "dojo").uri)
      assert_equal("http://example.com/users/dojo", simple_app.users[:user => "dojo"].uri)
    end
    
    def test_no_child
      assert_raises(NoMethodError) {simple_app.flooby}
    end

    def test_bigger_app
      assert_kind_of(Users, bigger_app.users)
      assert_kind_of(Users, bigger_app.users["dojo"])
      
      assert_kind_of(Articles, bigger_app.articles)
      assert_kind_of(Articles, bigger_app.articles["a-title"])
      
      assert_equal("http://example.com/users/", bigger_app.users.uri)
      assert_equal("http://example.com/users/dojo", bigger_app.users["dojo"].uri)
      
      assert_equal("http://example.com/users//articles/", bigger_app.articles.uri)
      assert_equal("http://example.com/users/dojo/articles/", bigger_app.articles(:user => "dojo").uri)
      assert_equal("http://example.com/users//articles/a-title", bigger_app.articles["a-title"].uri)
      
      assert_equal("http://example.com/users/dojo/articles/a-title", bigger_app.articles(:user => "dojo", :slug => "a-title").uri)
      assert_equal("http://example.com/users/dojo/articles/a-title", bigger_app.users["dojo"].articles["a-title"].uri)

      assert_raises(NoMethodError) {bigger_app.flooby}
    end

  end
end