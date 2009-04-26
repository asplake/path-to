require "path-to"
require "described_routes"

module PathTo
  module DescribedRoutes
    class Application < WithParams
      # An Array of DescribedRoutes::Resource objects
      attr_reader :resources

      # A Class (or at least something with a #new method) from which child objects will be created
      attr_reader :default_type

      # An HTTParty or similar
      attr_reader :http_client
      
      attr_reader :base
      
      def initialize(resources, base, default_type = Path, http_client = HTTPClient)
        @base, @resources, @default_type, @http_client = base, resources, default_type, http_client
        super(nil, nil, {})
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
        resource = resources_by_name[method.to_s]
        if resource
          base + resource.path_template
        end
      end
      
      def resources_by_name
        @resources_by_name ||= ::DescribedRoutes.all_by_name(resources)
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
          Addressable::URI.expand_template(t, string_keyed_params).to_s
        end
      end

    end
  end
end