require "path-to/path"
require "path-to/http_client"
require "addressable/template"

module PathTo
  #
  # Provides a Ruby client API interface to a web application.  Method calls on this Application object generate Path objects that
  # map (via URI templates held here on the Application) to the web application's URIs.
  #
  # Example:
  #
  #   app = PathTo::Application.new(
  #       :users    => "http://example.com/users/{user}",
  #       :articles => "http://example.com/users/{user}/articles/{slug}") do |app|
  #     def app.child_class_for(instance, method, params)
  #       {
  #         :users    => Users,
  #         :articles => Articles
  #       }[method]
  #     end
  #   end                                                         #=> PathTo::Application
  #
  #   app.users                                                   #=> http://example.com/users/ <Users>
  #   app.users(:user => "dojo")                                  #=> http://example.com/users/dojo <Users>
  #   app.articles(:user => "dojo", :slug => "my-article")        #=> http://example.com/users/dojo/articles/my-article <Articles>
  #   app.users[:user => "dojo"].articles[:slug => "my-article"]  #=> http://example.com/users/dojo/articles/my-article <Articles>
  #
  class Application < WithParams    
    # A Hash that maps method keys (Symbol) to URI templates (String)
    attr_reader :templates
    
    # A Class (or at least something with a #new method) from which child objects will be created
    attr_reader :default_type
    
    # An HTTParty or similar
    attr_reader :http_client
    
    #
    # Initializes an Application.  Parameters:
    #
    # [templates]     Initial value for the templates attribute, defaults to {}
    # [default_type]  Initial value for the default_type attribute, defaults to Path
    # [http_client]   An object through which http calls are invoked.  See HTTPClient and Path#http_client.
    #
    # Simple example:
    #
    #   # Model an application with just a "users" collection that generates Path objects
    #   simple_app = PathTo::Application.new(:users => "http://example.com/users/{user}")
    #
    # The constructor yields self, utilised in this example:
    #
    #   # Model an application with "users" and "articles" collections, represented here on the client side by Users and Articles objects   
    #   bigger_app = PathTo::Application.new(
    #       :users    => "http://example.com/users/{user}",
    #       :articles => "http://example.com/users/{user}/articles/{slug}") do |app|
    #     def app.child_class_for(instance, method, params)
    #       {
    #         :users    => Users,
    #         :articles => Articles
    #       }[method]
    #     end
    #   end
    #
    def initialize(templates = {}, default_type = Path, http_client = HTTPClient)
      super() # with default args
      @templates, @default_type, @http_client = templates, default_type, http_client
      yield self if block_given?
    end
    
    #
    # Determines whether this application &/or its child objects should respond to the given method, and if so returns a class from
    # which a new child instance (typically Path or a subclass thereof) will be created.  This implementation (easily overridden)
    # returns #default_type if there is a URI template defined for the method.
    #
    # Parameters:
    #
    # [instance] This application or (presumably) one of its child objects
    # [method]   The method invoked on the instance that has (presumably) been intercepted by instance#method_missing
    # [params]   The instance's params
    # 
    def child_class_for(instance, method, params)
      default_type if uri_template_for(method, params)
    end
    
    #
    # Returns self.  See Path#application.
    #
    def application
      self
    end
    
    #
    # Returns a URI template for the given method and params.  Parameters:
    #
    # [method]   The method invoked on the instance that has (presumably) been intercepted by instance#method_missing
    # [params]   The instance's params
    #
    # This implementation returns a value from the #templates Hash, keyed by method (params is ignored).
    #
    #--
    # TODO Consider taking an instance as the first parameter, as #child_class_for does
    #
    def uri_template_for(method, params = {})
      templates[method]
    end
    
    #
    # Generates a URI, looking up a URI template (via #uri_template_for) and getting it formatted with the params.
    #
    #--
    # TODO Consider taking an instance as the first parameter, as #child_class_for does
    #
    def uri_for(method, params = {})
      # TODO it's a 1-line fix to Addressable to permit symbols (etc) as keys
      if (t = uri_template_for(method, params))
        string_keyed_params = params.keys.inject({}){|hash, key| hash[key.to_s] = params[key]; hash}
        Addressable::Template.new(t).expand(string_keyed_params).to_s
      end
    end
  end
end
