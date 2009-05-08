require "path-to"
require "described_routes/resource_template"

module PathTo
  module DescribedRoutes
    class TemplatedPath < PathTo::Path
      attr_reader :resource_template
      
      def initialize(parent, service, params, resource_template)
        super(parent, resource_template.name, params)
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
        @uri_template ||= resource_template.uri_template || (application.base + resource_template.path_template)
      end
      
      def uri
        @uri ||= begin
          Addressable::Template.new(uri_template).expand(params).to_s
        end
      end
      
      #
      # Finds (once) the application in the parent hierarchy.
      #
      def application
        @application ||= parent.application if parent
      end
      
      # Delegated to the application
      def child_class_for(instance, method, params, template)
        application.child_class_for(instance, method, params, template)
      end
      
      #
      # Creates a child instance with new params, potentially finding a nested resource template that takes the additional params
      #
      def [](params = {})
        keys = self.params.merge(params).keys
        child_resource_template = resource_template.resource_templates.detect{ |t|
          t.rel.nil? && (t.params - keys).empty?
        } || resource_template
        child_class = child_class_for(self, nil, params, child_resource_template)
        child(child_class, nil, params, child_resource_template)
      end      
      
      #
      # Tries to respond to a missing method.  We can do so if
      #
      # 1. we can find a resource template with rel matching the method name (direct children only)
      # 2. #child_class_for returns a class or other factory object capable of creating a new child instance
      #
      # Otherwise we invoke super in the hope of avoiding any hard-to-debug behaviour!
      #
      def method_missing(method, *args)
        child_resource_template = resource_template.resource_templates.detect{|t| t.rel == method.to_s}
        if child_resource_template && (child_class = child_class_for(self, method, params, child_resource_template))
          params = args.inject(Hash.new){|h, arg| h.merge(arg)}
          child(child_class, method, params, child_resource_template)
        else
          super
        end
      end
      
    end
    
    class Application < WithParams
      # An Array of DescribedRoutes::Resource objects
      attr_reader :resource_templates

      # A Class (or at least something with a #new method) from which child objects will be created
      attr_reader :default_type

      # An HTTParty or similar
      attr_reader :http_client
      
      # Base URI of the application
      attr_reader :base
      
      # Hash of options to be included in HTTP method calls
      attr_reader :http_options
      
      def initialize(options)
        super(options[:parent], options[:service], options[:params])

        @base = options[:base]
        @base.sub(/\/$/, '') if base
        @default_type = options[:default_type] || TemplatedPath
        @http_client = options[:http_client] || HTTPClient
        @http_options = options[:http_options]
        
        @resource_templates = options[:resource_templates]
        unless @resource_templates
          if (json = options[:json])
            @resource_templates = ::DescribedRoutes::ResourceTemplate.parse_json(json)
          elsif (yaml = options[:yaml])
            @resource_templates = ::DescribedRoutes::ResourceTemplate.parse_yaml(yaml)
          elsif (xml = options[:xml])
            @resource_templates = ::DescribedRoutes::ResourceTemplate.parse_xml(xml)
          end
        end
        
        if parent
          @base ||= parent.base
          @default_type ||= parent.default_type
          @http_client ||= parent.http_client
          @resource_templates ||= parent.resource_templates
          @http_options ||= parent.http_options
        end
      end
      
      #
      # Creates a copy of self with additional params
      #
      def [](params = {})
        self.class.new(:parent => self, :params => params)
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
        @resource_templates_by_name ||= ::DescribedRoutes::ResourceTemplate.all_by_name(resource_templates)
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
