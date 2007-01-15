# $Id$

require 'test/setup.rb'
require 'stringio'

module TestLogging

  class TestLogger < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
    end

    def test_initialize
      assert_raise(ArgumentError) {::Logging::Logger[:test]}
      assert_nothing_raised {::Logging::Logger.new(Object)}
    end

    def test_add
      log = ::Logging::Logger.new 'A'

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      assert_raise(TypeError) {log.add Object.new}
      assert_raise(TypeError) {log.add 'not an appender'}

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.add a
      assert_equal [a], appenders[]

      log.add a
      assert_equal [a], appenders[]

      log.add b
      assert_equal [a,b], appenders[]

      log.add c
      assert_equal [a,b,c], appenders[]

      log.add a, c
      assert_equal [a,b,c], appenders[]

      log.clear
      assert_equal [], appenders[]

      log.add a, c
      assert_equal [a,c], appenders[]
    end

    def test_additive
      root = ::Logging::Logger.new :root
      log  = ::Logging::Logger.new 'A'

      assert_raise(NoMethodError) {root.additive}
      assert_equal true, log.additive
    end

    def test_additive_eq
      root = ::Logging::Logger.new :root
      log  = ::Logging::Logger.new 'A'

      assert_raise(NoMethodError) {root.additive = false}
      assert_equal true, log.additive

      log.additive = false
      assert_equal false, log.additive
    end

    def test_appenders_eq
      log = ::Logging::Logger.new '42'

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      assert_raise(TypeError) {log.appenders = Object.new}
      assert_raise(TypeError) {log.appenders = 'not an appender'}

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.appenders = a, b, c
      assert_equal [a, b, c], appenders[]

      log.appenders = b
      assert_equal [b], appenders[]

      log.appenders = c, a, b
      assert_equal [c,a,b], appenders[]

      log.appenders = nil
      assert_equal [], appenders[]
    end

    def test_class_aref
      root = ::Logging::Logger[:root]
      assert_same root, ::Logging::Logger[:root]

      a = []
      assert_same ::Logging::Logger['Array'], ::Logging::Logger[Array]
      assert_same ::Logging::Logger['Array'], ::Logging::Logger[a]

      assert_not_same ::Logging::Logger['Array'], ::Logging::Logger[:root]
      assert_not_same ::Logging::Logger['A'], ::Logging::Logger['A::B']
    end

    def test_class_root
      root = ::Logging::Logger[:root]
      assert_same root, ::Logging::Logger.root
    end

    def test_clear
      log  = ::Logging::Logger.new 'Elliott'

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.add a, b, c
      assert_equal [a,b,c], appenders[]

      log.clear
      assert_equal [], appenders[]
    end

    def test_concat
      a1 = SioAppender.new 'a1'
      a2 = SioAppender.new 'a2'
      log = ::Logging::Logger.new 'A'

      ::Logging::Logger[:root].add a1
      assert_nil a1.readline
      assert_nil a2.readline

      log << "this is line one of the log file\n"
      assert_equal "this is line one of the log file\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log << "this is line two of the log file\n"
      log << "this is line three of the log file\n"
      assert_equal "this is line two of the log file\n", a1.readline
      assert_equal "this is line three of the log file\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a2
      log << "this is line four of the log file\n"
      assert_equal "this is line four of the log file\n", a1.readline
      assert_equal "this is line four of the log file\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.additive = false
      log << "this is line five of the log file\n"
      assert_equal "this is line five of the log file\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a1
      log << "this is line six of the log file\n"
      assert_equal "this is line six of the log file\n", a1.readline
      assert_equal "this is line six of the log file\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline
    end

    def test_level
      root = ::Logging::Logger.new :root
      log  = ::Logging::Logger.new 'A'

      assert_equal 0, root.level
      assert_equal 0, log.level

      root.level = :warn
      assert_equal 2, root.level
      assert_equal 0, log.level

      log.level = nil
      assert_equal 2, root.level
      assert_equal 2, log.level

      log.level = :error
      assert_equal 2, root.level
      assert_equal 3, log.level
    end

    def test_level_eq
      root = ::Logging::Logger.new :root
      log  = ::Logging::Logger.new 'A'

      assert_equal 0, root.level
      assert_equal 0, log.level

      assert_raise(ArgumentError) {root.level = -1}
      assert_raise(ArgumentError) {root.level =  6}
      assert_raise(ArgumentError) {root.level = Object}
      assert_raise(ArgumentError) {root.level = 'bob'}
      assert_raise(ArgumentError) {root.level = :wtf}

      root.level = 'INFO'
      assert_equal 1, root.level
      assert_equal 0, log.level

      root.level = :warn
      assert_equal 2, root.level
      assert_equal 0, log.level

      root.level = 'error'
      assert_equal 3, root.level
      assert_equal 0, log.level

      root.level = 4
      assert_equal 4, root.level
      assert_equal 0, log.level

      log.level = nil
      assert_equal 4, root.level
      assert_equal 4, log.level

      log.level = :DEBUG
      assert_equal 4, root.level
      assert_equal 0, log.level

      log.level = :off
      assert_equal 4, root.level
      assert_equal 5, log.level

      root.level = :all
      assert_equal 0, root.level
      assert_equal 5, log.level

      log.level = nil
      assert_equal 0, root.level
      assert_equal 0, log.level

      root.level = :warn
      assert_equal 2, root.level
      assert_equal 0, log.level

      root.level = nil
      assert_equal 0, root.level
      assert_equal 0, log.level
    end

    def test_log
      root = ::Logging::Logger[:root]
      root.level = 'info'

      a1 = SioAppender.new 'a1'
      a2 = SioAppender.new 'a2'
      log = ::Logging::Logger.new 'A Logger'

      root.add a1
      assert_nil a1.readline
      assert_nil a2.readline

      log.debug 'this should NOT be logged'
      assert_nil a1.readline
      assert_nil a2.readline

      log.info 'this should be logged'
      assert_equal " INFO  A Logger : this should be logged\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.warn 'this is a warning', [1,2,3,4]
      assert_equal " WARN  A Logger : this is a warning\n", a1.readline
      assert_equal " WARN  A Logger : <Array> 1234\n", a1.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a2
      log.error 'an error has occurred'
      assert_equal "ERROR  A Logger : an error has occurred\n", a1.readline
      assert_equal "ERROR  A Logger : an error has occurred\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.additive = false
      log.error 'another error has occurred'
      assert_equal "ERROR  A Logger : another error has occurred\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.add a1
      log.fatal 'fatal exception'
      assert_equal "FATAL  A Logger : fatal exception\n", a1.readline
      assert_equal "FATAL  A Logger : fatal exception\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      assert_equal false, log.debug
      assert_equal true, log.info
      assert_equal true, log.warn
      assert_equal true, log.error
      assert_equal true, log.fatal

      log.level = :warn
      assert_equal false, log.debug
      assert_equal false, log.info
      assert_equal true, log.warn
      assert_equal true, log.error
      assert_equal true, log.fatal

      assert_raise(NoMethodError) {log.critical 'this log level does not exist'}

      log.warn do
        str = 'a string of data'
        str
      end
      assert_equal " WARN  A Logger : a string of data\n", a1.readline
      assert_equal " WARN  A Logger : a string of data\n", a2.readline
      assert_nil a1.readline
      assert_nil a2.readline

      log.info do
        rb_raise(RuntimeError, "this block should not be executed")
      end
      assert_nil a1.readline
      assert_nil a2.readline
    end

    def test_log_eh
      ::Logging::Logger[:root].level = 'info'
      log = ::Logging::Logger['A Logger']

      assert_equal false, log.debug?
      assert_equal true, log.info?
      assert_equal true, log.warn?
      assert_equal true, log.error?
      assert_equal true, log.fatal?

      log.level = :warn
      assert_equal false, log.debug?
      assert_equal false, log.info?
      assert_equal true, log.warn?
      assert_equal true, log.error?
      assert_equal true, log.fatal?

      assert_raise(NoMethodError) do
        log.critical? 'this log level does not exist'
      end
    end

    def test_name
      root = ::Logging::Logger.new :root
      log  = ::Logging::Logger.new 'A'

      assert_equal 'root', root.name
      assert_equal 'A', log.name
    end

    def test_parent
      logger = ::Logging::Logger
      root = logger.new :root

      assert_raise(NoMethodError) {root.parent}

      assert_same root, logger['A'].parent
      assert_same logger['A'], logger['A::B'].parent
      assert_same logger['A::B'], logger['A::B::C::D'].parent
      assert_same logger['A::B'], logger['A::B::C::E'].parent
      assert_same logger['A::B'], logger['A::B::C::F'].parent

      assert_same logger['A::B'], logger['A::B::C'].parent
      assert_same logger['A::B::C'], logger['A::B::C::D'].parent
      assert_same logger['A::B::C'], logger['A::B::C::E'].parent
      assert_same logger['A::B::C'], logger['A::B::C::F'].parent

      assert_same logger['A::B::C::E'], logger['A::B::C::E::G'].parent
    end

    def test_remove
      log = ::Logging::Logger['X']

      appenders = lambda {log.instance_variable_get :@appenders}
      assert_equal [], appenders[]

      a = ::Logging::Appender.new 'test_appender_1'
      b = ::Logging::Appender.new 'test_appender_2'
      c = ::Logging::Appender.new 'test_appender_3'

      log.add a, b, c
      assert_equal [a,b,c], appenders[]

      assert_raise(TypeError) {log.remove Object.new}
      assert_raise(TypeError) {log.remove 10}

      log.remove b
      assert_equal [a,c], appenders[]

      log.remove 'test_appender_1'
      assert_equal [c], appenders[]

      log.remove c
      assert_equal [], appenders[]

      log.remove a, b, c
      assert_equal [], appenders[]

      log.add a, b, c
      assert_equal [a,b,c], appenders[]

      log.remove a, c
      assert_equal [b], appenders[]
    end

    def test_spaceship
      logs = %w(
        A  A::B  A::B::C  A::B::C::D  A::B::C::E  A::B::C::E::G  A::B::C::F
      ).map {|x| ::Logging::Logger[x]}
      logs.unshift ::Logging::Logger[:root]

      logs.inject do |a,b|
        assert_equal(-1, a <=> b, "'#{a.name}' <=> '#{b.name}'")
        b
      end

      assert_equal 1, logs[1] <=> ::Logging::Logger[:root]
      assert_raise(ArgumentError) {logs[1] <=> Object.new}
      assert_raise(ArgumentError) {::Logging::Logger[:root] <=> 'string'}
    end

    def test_trace
      log = ::Logging::Logger[:root]
      assert_equal false, log.trace

      log.trace = true
      assert_equal true, log.trace

      log = ::Logging::Logger['A']
      assert_equal false, log.trace

      log.trace = true
      assert_equal true, log.trace
    end

  end  # class TestLogger

  class SioAppender < ::Logging::Appenders::IO

    def initialize( name, opts = {} )
      @sio = StringIO.new
      super(name, @sio, opts)
      begin readline rescue EOFError end
    end

    def readline
      @pos ||= 0
      @sio.seek @pos
      begin
        line = @sio.readline
        @pos = @sio.tell
        line
      rescue EOFError
        nil
      end
    end

  end  # class SioAppender
end  # module TestLogging

# EOF
