# $Id$

require 'test/setup.rb'

module TestLogging
module TestAppenders

  class TestStdOut < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      appender = ::Logging::Appenders::StdOut.new
      assert_equal 'stdout', appender.name
      assert_same STDOUT, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDOUT.closed?
    end

  end  # class TestStdOut

  class TestStdErr < Test::Unit::TestCase

    def test_initialize
      appender = ::Logging::Appenders::StdErr.new
      assert_equal 'stderr', appender.name
      assert_same STDERR, appender.instance_variable_get(:@io)

      appender.close
      assert_equal true, appender.closed?
      assert_equal false, STDERR.closed?
    end

  end  # class TestStdErr

end  # module TestAppenders
end  # module TestLogging

# EOF
