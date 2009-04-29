require "test/unit"
require "path-to/with_params"

module PathTo
  
  class TestWithParams < Test::Unit::TestCase
    attr_reader :root, :s1
    
    class WithParamsSubclass1 < WithParams
      def child_class_for(instance, service, params)
        WithParamsSubclass2
      end
    end

    class WithParamsSubclass2 < WithParams
    end
    
    def setup
      @root = WithParams.new(nil, :root, :x => 1)
      @s1 = WithParamsSubclass1.new
    end
    
    def test_params
      assert_equal({}, WithParams.new.params)
      assert_equal({:x => 1}, root.params)
      assert_equal({:x => 1}, root.child.params)
      assert_equal({:x => 2}, root.child(nil, nil, {:x => 2}).params)
      assert_equal({:x => 2}, root.child(nil, nil, {:x => 2}).child!.params)
      assert_equal({:x => 1, :y => 2}, root.child(nil, nil, {:y => 2}).params)
    end
    
    def test_child_type
      assert_kind_of(WithParams, root.child)
      assert_kind_of(WithParamsSubclass2, s1.child)
      assert_kind_of(WithParamsSubclass2, s1.child.child)
    end
    
    def test_indexed_params
      assert_equal({:x => 1}, root[].params)
      assert_equal({:x => 2}, root[:x => 2].params)
      assert_equal({:x => 1, :y => 2}, root[:y => 2].params)
    end
    
    def test_method_missing
      assert_kind_of(WithParams, root.flooby)
      assert_equal({:x => 1}, root.flooby.params)
      assert_equal({:x => 1, :y => 2}, root.flooby[:y => 2].params)
    end
  end
end