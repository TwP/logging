
require File.expand_path('../setup', File.dirname(__FILE__))

module TestLogging
module TestAppenders

  class TestPeriodicFlushing < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      @appender = Logging.appenders.string_io(
        'test_appender', :flush_period => 2
      )
      @appender.clear
      @sio = @appender.sio
      @levels = Logging::LEVELS
      begin readline rescue EOFError end
      Thread.pass  # give the flusher thread a moment to start
    end

    def teardown
      @appender.close
      @appender = nil
      super
    end

    def test_flush_period_set
      assert_equal 2, @appender.flush_period
      assert_equal Logging::Appenders::Buffering::DEFAULT_BUFFER_SIZE, @appender.auto_flushing

      @appender.flush_period = '01:30:45'
      assert_equal 5445, @appender.flush_period

      @appender.flush_period = '245'
      assert_equal 245, @appender.flush_period

      @appender.auto_flushing = true
      assert_equal Logging::Appenders::Buffering::DEFAULT_BUFFER_SIZE, @appender.auto_flushing

      @appender.auto_flushing = 200
      assert_equal 200, @appender.auto_flushing
    end

    def test_periodic_flusher_running
      flusher = @appender.instance_variable_get(:@periodic_flusher)

      assert_instance_of Logging::Appenders::Buffering::PeriodicFlusher, flusher
      assert flusher.waiting?, 'the periodic flusher should be waiting for a signal'
    end

    def test_append
      event = Logging::LogEvent.new('TestLogger', @levels['warn'],
                                    [1, 2, 3, 4], false)
      @appender.append event
      @appender.append event
      event.level = @levels['debug']
      event.data = 'the big log message'
      @appender.append event

      assert_nil(readline)
      sleep 3

      assert_equal " WARN  TestLogger : <Array> #{[1, 2, 3, 4]}\n", readline
      assert_equal " WARN  TestLogger : <Array> #{[1, 2, 3, 4]}\n", readline
      assert_equal "DEBUG  TestLogger : the big log message\n", readline
      assert_nil(readline)

      @appender.close
      assert_raise(RuntimeError) {@appender.append event}
    end
=begin
    def test_append_error
      # setup an internal logger to capture error messages from the IO
      # appender
      log = Logging.appenders.string_io('__internal_io')
      Logging.logger[Logging].add_appenders(log)
      Logging.logger[Logging].level = 'all'


      # close the string IO object so we get an error
      @sio.close
      event = Logging::LogEvent.new('TestLogger', @levels['warn'],
                                    [1, 2, 3, 4], false)
      @appender.append event
      assert_nil(log.readline)

      @appender.append event
      assert_nil(log.readline)

      @appender.append event
      assert_equal "INFO  Logging : appender \"test_appender\" has been disabled", log.readline.strip
      assert_equal "ERROR  Logging : <IOError> not opened for writing", log.readline.strip

      assert_equal false, @appender.closed?
      assert_equal 5, @appender.level
    end

    def test_auto_flushing
      assert_raise(ArgumentError) {
        @appender.auto_flushing = Object.new
      }

      assert_raise(ArgumentError) {
        @appender.auto_flushing = -1
      }

      @appender.auto_flushing = 0
      assert_equal Logging::Appenders::Buffering::DEFAULT_BUFFER_SIZE, @appender.auto_flushing
    end

    def test_close
      assert_equal false, @sio.closed?
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @sio.closed?
      assert_equal true, @appender.closed?

      [STDIN, STDERR, STDOUT].each do |io|
        @appender = Logging.appenders.io('test', io)
        @appender.close
        assert_equal false, io.closed?
        assert_equal true, @appender.closed?
      end
    end

=end
  private
    def readline
      @appender.readline
    end

  end  # class TestBufferedIO

end  # module TestAppenders
end  # module TestLogging

# EOF
