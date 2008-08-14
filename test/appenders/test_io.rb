
require File.join(File.dirname(__FILE__), %w[.. setup])

module TestLogging
module TestAppenders

  class TestIO < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.init
      @levels = ::Logging::LEVELS

      @sio = StringIO.new
      @appender = ::Logging::Appenders::IO.new 'test_appender', @sio
      begin readline rescue EOFError end
    end

    def test_append
      event = ::Logging::LogEvent.new('TestLogger', @levels['warn'],
                                      [1, 2, 3, 4], false)
      @appender.append event
      assert_equal " WARN  TestLogger : <Array> #{[1, 2, 3, 4]}\n", readline
      assert_raise(EOFError) {readline}

      event.level = @levels['debug']
      event.data = 'the big log message'
      @appender.append event
      assert_equal "DEBUG  TestLogger : the big log message\n", readline
      assert_raise(EOFError) {readline}

      @appender.close
      assert_raise(RuntimeError) {@appender.append event}
    end

    def test_append_error
      # setup an internal logger to capture error messages from the IO
      # appender
      log = StringIO.new
      Logging::Logger[Logging].add_appenders(
        Logging::Appenders::IO.new('__internal_io', log)
      )
      Logging::Logger[Logging].level = 'all'


      # close the string IO object so we get an error
      @sio.close
      event = ::Logging::LogEvent.new('TestLogger', @levels['warn'],
                                      [1, 2, 3, 4], false)
      @appender.append event

      log.seek 0
      assert_equal "ERROR  Logging : <IOError> not opened for writing", log.readline.strip

      assert_equal false, @appender.closed?
      assert_equal 5, @appender.level
    end

    def test_close
      assert_equal false, @sio.closed?
      assert_equal false, @appender.closed?

      @appender.close
      assert_equal true, @sio.closed?
      assert_equal true, @appender.closed?

      [STDIN, STDERR, STDOUT].each do |io|
        @appender = ::Logging::Appenders::IO.new 'test', io
        @appender.close
        assert_equal false, io.closed?
        assert_equal true, @appender.closed?
      end
    end

    def test_concat
      @appender << "this is a test message\n"
      assert_equal "this is a test message\n", readline
      assert_raise(EOFError) {readline}

      @appender << "this is another message\n"
      @appender << "some other line\n"
      assert_equal "this is another message\n", readline
      assert_equal "some other line\n", readline
      assert_raise(EOFError) {readline}

      @appender.close
      assert_raise(RuntimeError) {@appender << 'message'}
    end

    def test_concat_error
      # setup an internal logger to capture error messages from the IO
      # appender
      log = StringIO.new
      Logging::Logger[Logging].add_appenders(
        Logging::Appenders::IO.new('__internal_io', log)
      )
      Logging::Logger[Logging].level = 'all'

      # close the string IO object so we get an error
      @sio.close
      @appender << 'oopsy'

      log.seek 0
      assert_equal "ERROR  Logging : <IOError> not opened for writing", log.readline.strip

      # and the appender does not close itself
      assert_equal false, @appender.closed?
      assert_equal 5, @appender.level
    end

    def test_flush
      ary = []
      @sio.instance_variable_set :@ary, ary
      def @sio.flush() @ary << :flush end

      @appender.flush
      assert_equal :flush, ary.pop
    end

    def test_initialize
      assert_raise(EOFError) {@sio.readline}
      assert_raise(TypeError) {::Logging::Appenders::IO.new 'test', []}
    end

    private
    def readline
      @pos ||= 0
      @sio.seek @pos
      line = @sio.readline
      @pos = @sio.tell
      line
    end

  end  # class TestIO

end  # module TestAppenders
end  # module TestLogging

# EOF
