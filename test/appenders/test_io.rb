# $Id$

require 'test/setup.rb'
require 'stringio'

module TestLogging
module TestAppenders

  class TestIO < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.define_levels %w(debug info warn error fatal)
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
      @sio.close
      event = ::Logging::LogEvent.new('TestLogger', @levels['warn'],
                                      [1, 2, 3, 4], false)
      assert_raise(IOError) {@appender.append event}
      assert_equal true, @appender.closed?
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
      @sio.close
      assert_raise(IOError) {@appender << 'oopsy'}
      assert_equal true, @appender.closed?
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
