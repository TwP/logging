# $Id$

require File.join(File.dirname(__FILE__), %w[.. setup])

module TestLogging
module TestAppenders

  class TestStdout < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      appender = ::Logging::Appenders::Stdout.new
      assert_equal 'stdout', appender.name
      assert_same STDOUT, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDOUT.closed?
    end

  end  # class TestStdout

  class TestStderr < Test::Unit::TestCase

    def test_initialize
      appender = ::Logging::Appenders::Stderr.new
      assert_equal 'stderr', appender.name
      assert_same STDERR, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDERR.closed?
    end

  end  # class TestStderr

end  # module TestAppenders
end  # module TestLogging

# EOF
