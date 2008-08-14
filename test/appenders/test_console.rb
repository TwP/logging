
require File.join(File.dirname(__FILE__), %w[.. setup])

module TestLogging
module TestAppenders

  class TestStdout < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      ::Logging::Repository.instance

      appender = ::Logging::Appenders::Stdout.new
      assert_equal 'stdout', appender.name
      assert_same STDOUT, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDOUT.closed?

      appender = ::Logging::Appenders::Stdout.new('foo')
      assert_equal 'foo', appender.name

      appender = ::Logging::Appenders::Stdout.new(:level => :warn)
      assert_equal 'stdout', appender.name
      assert_equal 2, appender.level

      appender = ::Logging::Appenders::Stdout.new('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

  end  # class TestStdout

  class TestStderr < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      ::Logging::Repository.instance

      appender = ::Logging::Appenders::Stderr.new
      assert_equal 'stderr', appender.name
      assert_same STDERR, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDERR.closed?

      appender = ::Logging::Appenders::Stderr.new('foo')
      assert_equal 'foo', appender.name

      appender = ::Logging::Appenders::Stderr.new(:level => :warn)
      assert_equal 'stderr', appender.name
      assert_equal 2, appender.level

      appender = ::Logging::Appenders::Stderr.new('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

  end  # class TestStderr

end  # module TestAppenders
end  # module TestLogging

# EOF
