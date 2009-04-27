require "path-to"
require "described_routes"

module PathTo
  module DescribedRoutes
    class TemplatedPath < WithParams
      attr_reader :resource_template
      
      def initialize(parent, service, params, resource_template)
        super(parent, service, params)
        @resource_template = resource_template
        
        missing_params = resource_template.params - params.keys
        unless missing_params.empty?
          raise ArgumentError.new(
                  "Missing params #{missing_params.join(', ')} " + 
                  "(template #{resource_template.name.inspect}," +
                  " path_template #{resource_template.path_template.inspect}," +
                  " params #{params.inspect})")
          end
      end
      
      def uri_template
        @uri_template ||= application.base + resource_template.path_template
      end
      
      def uri
        @uri ||= begin
          string_keyed_params = params.keys.inject({}){|hash, key| hash[key.to_s] = params[key]; hash}
          Addressable::URI.expand_template(uri_template, string_keyed_params).to_s
        end
      end
      
      #
      # Finds (once) the application in the parent hierarchy.
      #
      def application
        @application ||= parent.application if parent
      end
    end
    
    class Application < WithParams
      # An Array of DescribedRoutes::Resource objects
      attr_reader :resources

      # A Class (or at least something with a #new method) from which child objects will be created
      attr_reader :default_type

      # An HTTParty or similar
      attr_reader :http_client
      
      attr_reader :base
      
      def initialize(resources, base, params = {}, default_type = TemplatedPath, http_client = HTTPClient)
        @base, @resources, @default_type, @http_client = base, resources, default_type, http_client
        super(nil, nil, params)
      end
      
      #
      # Tries to respond to a missing method.  We can do so if
      #
      # 1. we have a resource template matching the method name
      # 2. #child_class_for returns a class or other factory object capable of creating a new child instance
      #
      # Otherwise we invoke super in the hope of avoiding any hard-to-debug behaviour!
      #
      def method_missing(method, *args)
        resource_template = resource_templates_by_name[method.to_s]
        if resource_template && (child_class = child_class_for(self, method, params, resource_template))
          params = args.inject(Hash.new){|h, arg| h.merge(arg)}
          child(child_class, method, params, resource_template)
        else
          super
        end
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
      def child_class_for(instance, method, params, template)
        default_type
      end
      
      #
      # Returns a hash of all ResourceTemplates (the tree flattened) keyed by name
      #
      def resource_templates_by_name
        @resource_templates_by_name ||= ::DescribedRoutes.all_by_name(resources)
      end

      #
      # Returns self.  See TemplatedPath#application.
      #
      def application
        self
      end
    end
  end
end
