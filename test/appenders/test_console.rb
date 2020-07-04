
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestAppenders

  class TestConsole < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      assert_raise(RuntimeError) { Logging::Appenders::Console.new("test") }
    end
  end

  class TestStdout < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      Logging::Repository.instance

      appender = Logging.appenders.stdout
      assert_equal 'stdout', appender.name

      io = appender.instance_variable_get(:@io)
      refute_same STDOUT, io
      assert_equal STDOUT.fileno, io.fileno

      appender.close
      assert appender.closed?
      assert io.closed?
      refute STDOUT.closed?

      appender = Logging.appenders.stdout('foo')
      assert_equal 'foo', appender.name

      appender = Logging.appenders.stdout(:level => :warn)
      assert_equal 'stdout', appender.name
      assert_equal 2, appender.level

      appender = Logging.appenders.stdout('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

  end  # class TestStdout

  class TestStderr < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      Logging::Repository.instance

      appender = Logging.appenders.stderr
      assert_equal 'stderr', appender.name

      io = appender.instance_variable_get(:@io)
      refute_same STDERR, io
      assert_same STDERR.fileno, io.fileno

      appender.close
      assert appender.closed?
      assert io.closed?
      refute STDERR.closed?

      appender = Logging.appenders.stderr('foo')
      assert_equal 'foo', appender.name

      appender = Logging.appenders.stderr(:level => :warn)
      assert_equal 'stderr', appender.name
      assert_equal 2, appender.level

      appender = Logging.appenders.stderr('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

  end  # class TestStderr

end  # module TestAppenders
end  # module TestLogging

