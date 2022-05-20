
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
      assert_same STDOUT, io
      assert_equal STDOUT.fileno, io.fileno

      appender = Logging.appenders.stdout('foo')
      assert_equal 'foo', appender.name

      appender = Logging.appenders.stdout(:level => :warn)
      assert_equal 'stdout', appender.name
      assert_equal 2, appender.level

      appender = Logging.appenders.stdout('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

    def test_reopen
      Logging::Repository.instance

      appender = Logging.appenders.stdout
      io = appender.instance_variable_get(:@io)

      appender.close
      assert appender.closed?
      refute io.closed?
      refute STDOUT.closed?

      appender.reopen
      refute appender.closed?

      new_io = appender.instance_variable_get(:@io)
      assert_same io, new_io
      refute new_io.closed?
      refute io.closed?
    end
  end

  class TestStderr < Test::Unit::TestCase
    include LoggingTestCase

    def test_initialize
      Logging::Repository.instance

      appender = Logging.appenders.stderr
      assert_equal 'stderr', appender.name

      io = appender.instance_variable_get(:@io)
      assert_same STDERR, io
      assert_equal STDERR.fileno, io.fileno

      appender = Logging.appenders.stderr('foo')
      assert_equal 'foo', appender.name

      appender = Logging.appenders.stderr(:level => :warn)
      assert_equal 'stderr', appender.name
      assert_equal 2, appender.level

      appender = Logging.appenders.stderr('bar', :level => :error)
      assert_equal 'bar', appender.name
      assert_equal 3, appender.level
    end

    def test_reopen
      Logging::Repository.instance

      appender = Logging.appenders.stderr
      io = appender.instance_variable_get(:@io)

      appender.close
      assert appender.closed?
      refute io.closed?
      refute STDERR.closed?

      appender.reopen
      refute appender.closed?

      new_io = appender.instance_variable_get(:@io)
      assert_same io, new_io
      refute new_io.closed?
      refute io.closed?
    end
  end
end
end

