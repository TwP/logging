# $Id$

require 'test/setup.rb'

module TestLogging

  class TestAppender < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super

      ::Logging.define_levels %w(debug info warn error fatal)
      @levels = ::Logging::LEVELS

      @event = ::Logging::LogEvent.new('', @levels['debug'], [], false)
      @appender = ::Logging::Appender.new 'test_appender'
    end

    def test_append
      assert_nothing_raised {@appender.append @event}

      @appender.close
      assert_raise(RuntimeError) {@appender.append @event}
    end

    def test_close
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @appender.closed?
    end

    def test_closed_eh
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @appender.closed?
    end

    def test_concat
      assert_nothing_raised {@appender << 'log message'}

      @appender.close
      assert_raise(RuntimeError)  {@appender << 'log message'}
    end

    def test_initialize
      assert_raise(TypeError) {::Logging::Appender.new 'test', :layout => []}

      layout = ::Logging::Layouts::Basic.new
      @appender = ::Logging::Appender.new 'test', :layout => layout
      assert_same layout, @appender.instance_variable_get(:@layout)
    end

    def test_layout
      assert_instance_of ::Logging::Layouts::Basic, @appender.layout
    end

    def test_layout_eq
      layout = ::Logging::Layouts::Basic.new
      assert_not_equal layout, @appender.layout

      assert_raise(TypeError) {@appender.layout = Object.new}
      assert_raise(TypeError) {@appender.layout = 'not a layout'}

      @appender.layout = layout
      assert_same layout, @appender.layout
    end

    def test_name
      assert_equal 'test_appender', @appender.name
    end

  end  # class TestAppender
end  # module TestLogging

# EOF
