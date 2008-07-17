
require File.join(File.dirname(__FILE__), %w[setup])

module TestLogging

  class TestUtils < Test::Unit::TestCase

    def test_getopt
      opts = {
        :foo => 'foo_value',
        'bar' => 'bar_value',
        'one' => '1',
        :two => '2',
        :three => 3.0
      }

      assert_equal('foo_value', opts.getopt(:foo))
      assert_equal('foo_value', opts.getopt('foo'))
      assert_equal(:foo_value, opts.getopt(:foo, :as => Symbol))

      assert_equal('bar_value', opts.getopt(:bar))
      assert_equal('bar_value', opts.getopt('bar'))

      assert_equal('1', opts.getopt(:one))
      assert_equal(1, opts.getopt('one', :as => Integer))
      assert_instance_of(Float, opts.getopt('one', :as => Float))

      assert_equal('2', opts.getopt(:two))
      assert_equal(['2'], opts.getopt(:two, :as => Array))

      assert_equal(3.0, opts.getopt(:three))
      assert_equal('3.0', opts.getopt('three', :as => String))

      assert_equal(nil, opts.getopt(:baz))
      assert_equal('default', opts.getopt('baz', 'default'))
      assert_equal(:default, opts.getopt(:key, 'default', :as => Symbol))
      assert_equal(['default'], opts.getopt('key', 'default', :as => Array))

      assert_equal(3.0, opts.getopt(:three, :as => Object))

      assert_nil opts.getopt(:key, :as => Symbol)
    end

  end  # class TestUtils
end  # module TestLogging

# EOF
