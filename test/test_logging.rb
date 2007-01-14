# $Id$

require 'test/setup.rb'

module TestLogging

  class TestLogging < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @levels = ::Logging::LEVELS
      @lnames = ::Logging::LNAMES
    end

    def test_define_levels_default
      empty = {}
      assert_equal empty, @levels
      assert_equal empty, @lnames
      assert_same false, ::Logging.const_defined?(:MAX_LEVEL_LENGTH)

      ::Logging::Repository.instance

      assert_equal 5, @levels.length
      assert_equal 5, @lnames.length
      assert_equal 5, ::Logging::MAX_LEVEL_LENGTH

      assert_equal 0, @levels['debug']
      assert_equal 1, @levels['info']
      assert_equal 2, @levels['warn']
      assert_equal 3, @levels['error']
      assert_equal 4, @levels['fatal']

      assert_equal 'DEBUG', @lnames[0]
      assert_equal 'INFO',  @lnames[1]
      assert_equal 'WARN',  @lnames[2]
      assert_equal 'ERROR', @lnames[3]
      assert_equal 'FATAL', @lnames[4]
    end

    def test_define_levels_special
      empty = {}
      assert_equal empty, @levels
      assert_equal empty, @lnames
      assert_same false, ::Logging.const_defined?(:MAX_LEVEL_LENGTH)

      assert_raise(ArgumentError) {::Logging.define_levels(1, 2, 3, 4)}

      ::Logging.define_levels :one, 'two', :THREE, 'FoUr', :sIx

      assert_equal 5, @levels.length
      assert_equal 5, @lnames.length
      assert_equal 5, ::Logging::MAX_LEVEL_LENGTH

      assert_equal 0, @levels['one']
      assert_equal 1, @levels['two']
      assert_equal 2, @levels['three']
      assert_equal 3, @levels['four']
      assert_equal 4, @levels['six']

      assert_equal 'ONE',   @lnames[0]
      assert_equal 'TWO',   @lnames[1]
      assert_equal 'THREE', @lnames[2]
      assert_equal 'FOUR',  @lnames[3]
      assert_equal 'SIX',   @lnames[4]
    end

    def test_define_levels_all_off
      empty = {}
      assert_equal empty, @levels
      assert_equal empty, @lnames
      assert_same false, ::Logging.const_defined?(:MAX_LEVEL_LENGTH)

      ::Logging.define_levels %w(a b all c off d)

      assert_equal 4, @levels.length
      assert_equal 4, @lnames.length
      assert_equal 1, ::Logging::MAX_LEVEL_LENGTH

      assert_equal 0, @levels['a']
      assert_equal 1, @levels['b']
      assert_equal 2, @levels['c']
      assert_equal 3, @levels['d']

      assert_equal 'A', @lnames[0]
      assert_equal 'B', @lnames[1]
      assert_equal 'C', @lnames[2]
      assert_equal 'D', @lnames[3]
    end

    def test_format_as
      assert_equal false, ::Logging.const_defined?('OBJ_FORMAT')

      assert_raises(ArgumentError) {::Logging.format_as 'string'}
      assert_raises(ArgumentError) {::Logging.format_as String}
      assert_raises(ArgumentError) {::Logging.format_as :what?}
      
      remove_const = lambda do |const|
        ::Logging.class_eval {remove_const const if const_defined? const}
      end

      ::Logging.format_as :string
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :string, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as :inspect
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :inspect, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]

      ::Logging.format_as :yaml
      assert ::Logging.const_defined?('OBJ_FORMAT')
      assert_equal :yaml, ::Logging::OBJ_FORMAT
      remove_const[:OBJ_FORMAT]
    end

  end  # class TestLogging
end  # module TestLogging

# EOF
