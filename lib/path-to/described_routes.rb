require "path-to"
require "described_routes"
require "link_header"

module PathTo
  #
  # Application and Path implementations for DescribedRoutes, each resource described by a ResourceTemplate
  #
  module DescribedRoutes
    #
    # Raised in the event of discovery protocol errors, e.g. responses other than 200 OK or missing headers.
    # Low-level exceptions are NOT swallowed.
    #
    class ProtocolError < Exception
    end
    
    #
    # Implements PathTo::Path, represents a resource described by a ResourceTemplate
    #
    class TemplatedPath < PathTo::Path
      attr_reader :resource_template
      
      #
      # Initialize a TemplatedPath.  Raises ArgumentError if params doesn't include all mandatory params expected by the resource
      # template.
      #
      # Parameters:
      #   [parent]   parent object path or application
      #   [service]  unused - resource_template.name is passed to super() instead.  TODO: refactor
      #   [params]   hash of params; will be merged with the parent's params and passed when required to the resource template's URI template
      #   [resource_template] metadata describing the web resource
      #
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
      
      #
      # Creates and caches the URI by filling in the resource template's URI template with params 
      #
      def uri
        @uri ||= resource_template.uri_for(params, application.base)
      end
      
      #
      # Finds and caches the application in the parent hierarchy.
      #
      def application
        @application ||= parent.application if parent
      end
      
      # Delegated to the application
      def child_class_for(instance, method, params, template)
        application.child_class_for(instance, method, params, template)
      end
      
      #
      # Creates a child instance with new params, potentially finding a nested resource template that takes the additional params.
      # May take a combination of positional and named parameters, e.g.
      #
      #   users["dojo", {"format" => "json"}]
      #
      # Positional parameters are unsupported however if a new child template is not identified.
      #
      def [](*args)
        positional_params, params_hash = extract_params(args, params)
        known_keys = params_hash.keys
        
        child_resource_template = resource_template.find_by_rel(nil).detect do |t|
          (t.positional_params(resource_template)[positional_params.length..-1] -  t.optional_params - known_keys).empty?
        end
        
        if child_resource_template
          # we have a new child resource template; apply any positional params to the hash
          complete_params_hash!(params_hash, child_resource_template.positional_params(resource_template), positional_params)
        else
          # we're just adding optional params, no new template identified
          unless positional_params.empty?
            raise ArgumentError.new(
                  "No matching child template; only named parameters can be used here. " +
                  "positional_params=#{positional_params.inspect}, params_hash=#{params_hash.inspect}")
          end
          child_resource_template = resource_template
        end
        
        child_class = child_class_for(self, nil, params_hash, child_resource_template)
        child(child_class, nil, params_hash, child_resource_template)
      end      
      
      #
      # Tries to respond to a missing method.  We can do so if
      #
      # 1. we can find a resource template with rel matching the method name (direct children only)
      # 2. #child_class_for returns a class or other factory object capable of creating a new child instance
      #
      # Otherwise we invoke super in the hope of avoiding any hard-to-debug behaviour!
      #
      # May take a combination of positional and named parameters, e.g.
      #
      #   users("dojo", "format" => "json")
      #
      def method_missing(method, *args)
        child_resource_template = resource_template.find_by_rel(method.to_s).first
        if child_resource_template && (child_class = child_class_for(self, method, params, child_resource_template))
          positional_params, params_hash = extract_params(args, params)
          complete_params_hash!(params_hash, child_resource_template.positional_params(resource_template), positional_params)
          child(child_class, method, params_hash, child_resource_template)
        else
          super
        end
      end
      
    end
    
    #
    # DescribedRoutes implementation of PathTo::Application.
    #
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
      
      def self.discover(url, options={})
        http_options = options[:http_options] || nil
        default_type = options[:default_type] || Path
        http_client  = options[:http_client]  || HTTPClient
        
        metadata_link = self.discover_metadata_link(url, http_client)
        unless metadata_link
          raise ProtocolError.new("no metadata link found")
        end

        json = http_client.get(metadata_link.href, :format => :text, :headers => {"Accept" => "application/json"})
        unless json
          raise ProtocolError.new("no json found")
        end

        self.new(options.merge(:json => json))
      end

      def self.discover_metadata_link(url, http_client)
        response = http_client.head(url, {"Accept" => "application/json"})
        unless response.kind_of?(Net::HTTPOK)
          raise ProtocolError.new("got response #{response.inspect} from #{url}")
        end
        link_header = LinkHeader.parse(response["Link"])

        app_templates_link = link_header.find_link(["rel", "describedby"], ["meta", "ResourceTemplates"])
        unless app_templates_link
          resource_template_link = link_header.find_link(["rel", "describedby"], ["meta", "ResourceTemplate"])
          if resource_template_link
            response = http_client.head(resource_template_link.href, {"Accept" => "application/json"})
            unless response.kind_of?(Net::HTTPOK)
              raise ProtocolError.new("got response #{response.inspect} from #{url}")
            end
            link_header = LinkHeader.parse(response["Link"])
            app_templates_link = link_header.find_link(["rel", "index"], ["meta", "ResourceTemplates"])
            unless app_templates_link
              raise ProtocolError.new("(2) couldn't find link with rel=\"index\" and meta=\"ResourceTemplates\" at #{resource_template_link.href}")
            end
          else
            unless app_templates_link
              raise ProtocolError.new("(1) couldn't find link with rel=\"described_by\" and meta=\"ResourceTemplates\" or meta=\"ResourceTemplate\" at #{url}")
            end
          end
        end
        app_templates_link
      end
      
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
            @resource_templates = ResourceTemplate::ResourceTemplates.new(JSON.parse(json))
          elsif (yaml = options[:yaml])
            @resource_templates = ResourceTemplate::ResourceTemplates.new(YAML.load(yaml))
          elsif (xml = options[:xml])
            @resource_templates = ResourceTemplate::ResourceTemplates.parse_xml(xml)
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
      def [](params)
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
        child_resource_template = resource_templates_by_name[method.to_s]
        if child_resource_template && (child_class = child_class_for(self, method, params, child_resource_template))
          positional_params, params_hash = extract_params(args, params)
          complete_params_hash!(params_hash, child_resource_template.positional_params(nil), positional_params)
          child(child_class, method, params_hash, child_resource_template)
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
        @resource_templates_by_name ||= resource_templates.all_by_name
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
