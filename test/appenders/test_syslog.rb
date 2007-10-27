# $Id$

require 'test/setup.rb'
require 'stringio'

module TestLogging
module TestAppenders

  class TestSyslog < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.define_levels %w(debug info warn error fatal)
      @levels = ::Logging::LEVELS
    end

    def teardown
      ::Syslog.close if ::Syslog.opened?
    end

    def test_append
      return if RUBY_PLATFORM =~ %r/cygwin/

      stderr = IO::pipe

      pid = fork do
        stderr[0].close
        STDERR.reopen(stderr[1])
        stderr[1].close

        appender = create_syslog
        event = ::Logging::LogEvent.new('TestLogger', @levels['info'],
                                        [1, 2, 3, 4], false)
        appender.append event
        event.level = @levels['debug']
        event.data = 'the big log message'
        appender.append event

        exit!
      end

      stderr[1].close
      Process.waitpid(pid)

      assert_equal("syslog_test:  INFO  TestLogger : <Array> 1234\n",
                   stderr[0].gets)
      assert_equal("syslog_test: DEBUG  TestLogger : the big log message\n",
                   stderr[0].gets)
    end

    def test_append_error
      appender = create_syslog
      appender.close

      event = ::Logging::LogEvent.new('TestLogger', @levels['warn'],
                                      [1, 2, 3, 4], false)
      assert_raise(RuntimeError) {appender.append event}
      assert_equal true, appender.closed?
    end

    def test_close
      appender = create_syslog
      assert_equal false, appender.closed?

      appender.close
      assert_equal true, appender.closed?
    end

    def test_concat
      return if RUBY_PLATFORM =~ %r/cygwin/
#     @appender << "this is a test message\n"
#     assert_equal "this is a test message\n", readline
#     assert_raise(EOFError) {readline}
#
#     @appender << "this is another message\n"
#     @appender << "some other line\n"
#     assert_equal "this is another message\n", readline
#     assert_equal "some other line\n", readline
#     assert_raise(EOFError) {readline}
#
#     @appender.close
#     assert_raise(RuntimeError) {@appender << 'message'}
    end

    def test_concat_error
      appender = create_syslog
      appender.close

      assert_raise(RuntimeError) {appender << 'oopsy'}
      assert_equal true, appender.closed?
    end


    private

    def create_syslog
      layout = ::Logging::Layouts::Pattern.new(:pattern => '%5l  %c : %m')
      ::Logging::Appenders::Syslog.new(
          'syslog_test',
          :logopt => ::Syslog::LOG_PERROR | ::Syslog::LOG_NDELAY,
          :facility => ::Syslog::LOG_USER,
          :layout => layout
      )
    end

  end  # class TestIO

end  # module TestAppenders
end  # module TestLogging

# EOF
