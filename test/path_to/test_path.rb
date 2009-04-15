require "test/unit"
require "mocha"
require "path-to/path"
require "path-to/application"

module PathTo
  class TestPath < Test::Unit::TestCase
    attr_reader :app, :users
    
    class TestPath < Path
    end

    def setup
      @app = Application.new(
          :users    => "http://example.com/users/{user}",
          :articles => "http://example.com/users/{user}/articles/{slug}")
      @users = @app.users
    end
    
    def test_application
      assert_equal(app, users.application)
      assert_equal(app, users.articles.application)
    end  

    def test_nil_application
      assert_nil(Path.new.application)
      assert_nil(Path.new[].application)
    end
    
    def test_child_class_for
      params = {:slug => "a-title"}
      app.expects(:child_class_for).with(users, :articles, params).returns(TestPath)
      assert_equal(TestPath, users.child_class_for(users, :articles, params))
    end
    
    def test_uri
      assert_equal("http://example.com/users/dojo", users[:user => "dojo"].uri)
    end
    
    def test_http_methods
      request_options = {:body => {:bar => :baz}}
      [:get, :put, :post, :delete].each do |method|
        app.http_client.expects(method).with("http://example.com/users/", request_options)
        users.send(method, request_options)
      end
    end
  end
end
