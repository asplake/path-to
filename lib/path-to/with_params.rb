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
    
    # Service identifier, typically a method symbol intercepted in #method_missing
    attr_reader :service
    
    # Parameter hash
    attr_reader :params

    #
    # Initialize a new WithParams object. Parameters:
    #
    # [parent]  Value for the parent attribute
    # [service] Value for the service attribute  
    # [params]  Value for the params attribute
    #
    def initialize(parent = nil, service = nil, params = {})
      @parent, @service, @params = parent, service, params
    end

    #
    # Creates a child instance.  Parameters:
    #
    # [child_class] The class of the new instance, calls #child_class_for to determine this if none supplied
    # [service]     Value for the new instance's service attribute, inherited from self (the parent) if none supplied
    # [params]      The new instance's params, will be merged with self's (the parent's) params
    #
    def child(child_class = nil, service = nil, params = {})
      child_class ||= child_class_for(instance, service, params)
      service ||= self.service
      params = self.params.merge(params)
      child_class.new(self, service, params)
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
  end
end
