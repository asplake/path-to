module PathTo
  #
  # Chaining parameter collection.  Example:
  #
  #   p = WithParams.new.foo(:bar => "baz").fee[:fi => "fo"]  #=> <WithParams>
  #   p.service                                               #=> :fee
  #   p.params                                                #=> {:bar => "baz", :fi => "fo"}
  #
  class WithParams
    # Parent object, presumably of type WithParams or descendant
    attr_reader :parent
        
    # Parameter hash
    attr_reader :params

    # Service identifier, typically a method symbol intercepted in #method_missing by parent
    attr_reader :service

    #
    # Initialize a new WithParams object. Parameters:
    #
    # [parent]  Value for the parent attribute
    # [service] Value for the service attribute  
    # [params]  Value for the params attribute
    #
    def initialize(parent = nil, service = nil, params = {})
      @parent, @service, @params = parent, service, params || {}
    end

    #
    # Creates a child instance.  Parameters:
    #
    # [child_class] The class of the new instance, calls #child_class_for to determine this if none supplied
    # [service]     Value for the new instance's service attribute, inherited from self (the parent) if none supplied
    # [params]      The new instance's params, will be merged with self's (the parent's) params
    #
    def child(child_class = nil, service = nil, params = {}, *other_args)
      child_class ||= child_class_for(instance, service, params)
      service ||= self.service
      params = self.params.merge(params || {})
      child_class.new(self, service, params, *other_args)
    end

    #
    # Creates a child instance with new params.  Subclasses might override this to take values instead of hashes, as follows:
    #
    #   def [](value)
    #     super(:key => value)
    #   end
    #
    def [](params = {})
      child(self.class, self.service, params)
    end
  
    #
    # Determines the class of a new child, given the parent instance, service and params
    #
    def child_class_for(instance, service, params)
      self.class
    end

    #
    # Determines whether we can respond to method (missing or otherwise).  We can respond to a missing method if #child_class_for
    # returns a class for a new child.
    #
    def respond_to?(method)
      child_class_for(self, method, params) || super
    end
    
    #
    # Tries to respond to a missing method.  We can do so if
    #
    # 1. any args are hashes (merged to make a params hash), and
    # 2. #child_class_for returns a class or other factory object capable of creating a new child instance
    #
    # In all other cases and in the case of error we invoke super in the hope of avoiding any hard-to-debug behaviour!
    #
    def method_missing(method, *args)
      begin
        params = args.inject(Hash.new){|h, arg| h.merge(arg)}
        if (child_class = child_class_for(self, method, params))
          child(child_class, method, params)
        else
          super
        end
      rescue
        super
      end
    end
    
    #
    # Separates positional params from hash params
    # TODO: this is initially just for the DescribedRoutes implementation but there will be some refactoring to do
    #
    def extract_params(args, params_hash={})#:nodoc:
      positional_params = []
      params_hash = params_hash.clone
      args.each do |arg|
        if arg.kind_of?(Hash)
          params_hash.merge!(arg)
        else
          positional_params << arg
        end
      end
      [positional_params, params_hash]
    end
    
    #
    # Updates params_hash with positional parameters
    # TODO: this is initially just for the DescribedRoutes implementation but there will be some refactoring to do
    #
    def complete_params_hash!(params_hash, names, values)#:nodoc:
      names[0...values.length].each_with_index do |k, i|
        params_hash[k] = values[i]
      end
    end
  end
end
